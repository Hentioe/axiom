defmodule Axiom.Chat.Completions do
  @moduledoc false

  alias Axiom.JSON

  defmodule StreamingError do
    @moduledoc false

    defexception [:message, :detail, chunks: []]
  end

  defmodule Completion do
    @moduledoc false

    require Logger

    defstruct [:async_request, :body_stream]

    @type t :: %__MODULE__{async_request: (-> Finch.request_ref()), body_stream: Enumerable.t()}

    def resp_mapping({:status, 401}) do
      {:error, :unauthorized}
    end

    def resp_mapping({:status, _}) do
      :cont
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
      raise StreamingError, message: "Unauthorized", detail: detail, chunks: chunks
    end

    defp raise_error(%{kind: :transport, reason: reason} = detail, chunks) do
      raise StreamingError, message: "Transport error: #{reason}", detail: detail, chunks: chunks
    end

    defp next_fun(ref) do
      case mapping_receive(ref) do
        {:data, data} ->
          {[data], ref}

        :cont ->
          {[], ref}

        :done ->
          {:halt, ref}

        {:error, detail} ->
          raise_error(detail, ref)
      end
    end

    defp cleanup(_chunks), do: :cleanup

    def new(async_request) do
      body_stream = Stream.resource(async_request, &next_fun/1, &cleanup/1)

      %__MODULE__{async_request: async_request, body_stream: body_stream}
    end
  end

  @spec create(Axiom.t(), model :: String.t(), messages :: list(), opts :: map()) ::
          Completion.t()
  def create(axiom, model, messages, opts \\ %{})
      when is_struct(axiom, Axiom) and is_list(messages) do
    body = apply(axiom.provider, :inputgen, [model, messages, opts])

    headers =
      [
        {"authorization", "Bearer #{axiom.api_key}"},
        {"content-type", "application/json"}
      ] ++ axiom.headers

    async_request = fn ->
      :post
      |> Finch.build("#{axiom.base_url}/chat/completions", headers, JSON.encode!(body))
      |> Finch.async_request(axiom.finch_name || Axiom.Finch,
        request_timeout: axiom.request_timeout || :infinity,
        receive_timeout: axiom.receive_timeout || :infinity,
        pool_timeout: :infinity
      )
    end

    Completion.new(async_request)
  end
end
