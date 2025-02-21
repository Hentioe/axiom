defmodule Axiom.Chat.Completions do
  @moduledoc false

  alias Axiom.JSON

  defmodule AsyncRespError do
    @moduledoc false

    defexception [:message, :detail, chunks: []]
  end

  defmodule Completion do
    @moduledoc false

    require Logger

    defstruct [:async_request, :body_stream, :provider]

    @type t :: %__MODULE__{async_request: (-> Finch.request_ref()), body_stream: Enumerable.t()}

    @spec resp_mapping(any) ::
            :cont
            | :done
            | :unauthorized
            | {:data, String.t()}
            | {:error, %{kind: atom(), reason: any()}}
            | {:unexpected_status, non_neg_integer()}
    def resp_mapping({:status, 401}) do
      :unauthorized
    end

    def resp_mapping({:status, 200}) do
      :cont
    end

    def resp_mapping({:status, code}) do
      {:unexpected_status, code}
    end

    def resp_mapping({:headers, _}) do
      :cont
    end

    def resp_mapping({:data, <<"data: [DONE]\n\n">>}) do
      :cont
    end

    def resp_mapping({:data, data}) do
      {:data, data}
    end

    def resp_mapping(:done) do
      :done
    end

    def resp_mapping({:error, error}) when is_struct(error, Mint.TransportError) do
      {:error, %{kind: :transport, reason: error.reason}}
    end

    def resp_mapping(resp) do
      Logger.warning("Received unknown response: #{inspect(resp)}")

      :cont
    end

    defp mapping_receive(ref) do
      receive do
        {^ref, resp} -> resp_mapping(resp)
      end
    end

    defp raise_error(:unauthorized = detail, chunks) do
      raise AsyncRespError, message: "Unauthorized", detail: detail, chunks: chunks
    end

    defp raise_error(%{kind: :transport, reason: reason} = detail, chunks) do
      raise AsyncRespError, message: "Transport error: #{reason}", detail: detail, chunks: chunks
    end

    defp raise_error(%{kind: :unexpected_status, code: code} = detail, chunks) do
      raise AsyncRespError, message: "Unexpected status: #{code}", detail: detail, chunks: chunks
    end

    defp start_fun(provider, async_request) do
      ref = async_request.()

      %{ref: ref, state: %{}, chunks: [], provider: provider}
    end

    defp next_fun(
           %{ref: ref, state: %{unexpected_status: code}, chunks: chunks, provider: provider} =
             acc
         ) do
      case mapping_receive(ref) do
        {:data, data} ->
          raise_error(
            %{kind: :unexpected_status, code: code, body: apply(provider, :decoderr, [data])},
            chunks
          )

        :cont ->
          {[], acc}

        :done ->
          {:halt, acc}

        {:error, detail} ->
          raise_error(detail, chunks)
      end
    end

    defp next_fun(%{ref: ref, chunks: chunks} = acc) do
      case mapping_receive(ref) do
        {:data, data} ->
          acc = %{acc | chunks: chunks ++ [data]}

          {[data], acc}

        :cont ->
          {[], acc}

        :done ->
          {:halt, acc}

        {:unexpected_status, code} ->
          # Attach status to capture the error body later
          acc = %{acc | state: %{unexpected_status: code}}

          {[], acc}

        :unauthorized ->
          raise_error(:unauthorized, chunks)

        {:error, detail} ->
          raise_error(detail, chunks)
      end
    end

    defp cleanup(_chunks), do: :cleanup

    def new(provider, async_request) do
      body_stream =
        Stream.resource(fn -> start_fun(provider, async_request) end, &next_fun/1, &cleanup/1)

      %__MODULE__{provider: provider, async_request: async_request, body_stream: body_stream}
    end
  end

  @spec create(Axiom.t(), model :: String.t(), messages :: list(), opts :: map()) ::
          Completion.t()
  def create(axiom, model, messages, opts \\ %{})
      when is_struct(axiom, Axiom) and is_list(messages) do
    body = apply(axiom.provider, :inputgen, [model, messages, opts])

    headers =
      [
        apply(axiom.provider, :authgen, [axiom.api_key]),
        {"content-type", "application/json"}
      ] ++ axiom.headers

    endpoint = apply(axiom.provider, :endpoint, [:completions])

    async_request = fn ->
      :post
      |> Finch.build("#{axiom.base_url}#{endpoint}", headers, JSON.encode!(body))
      |> Finch.async_request(axiom.finch_name || Axiom.Finch,
        request_timeout: axiom.request_timeout || :infinity,
        receive_timeout: axiom.receive_timeout || :infinity,
        pool_timeout: 15 * 1000
      )
    end

    Completion.new(axiom.provider, async_request)
  end
end
