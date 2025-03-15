defmodule Axiom.Chat.Completions do
  @moduledoc false

  alias Axiom.JSON

  defmodule ResponseError do
    @moduledoc false

    defexception [:message, :kind, :reason, :detail, chunks: []]

    @type t :: %__MODULE__{
            message: String.t(),
            kind: atom(),
            reason: any(),
            detail: any(),
            chunks: [map()]
          }
  end

  defmodule Completion do
    @moduledoc false

    require Logger

    defstruct [:axiom, :model, :async_request, :body_stream]

    @type t :: %__MODULE__{
            axiom: Axiom.t(),
            model: String.t(),
            async_request: (-> Finch.request_ref()),
            body_stream: Enumerable.t()
          }

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

    defp raise_error(:unauthorized, chunks) do
      raise ResponseError,
        message: "Unauthorized",
        kind: :api,
        reason: :unauthorized,
        chunks: chunks
    end

    defp raise_error(%{kind: :transport, reason: reason}, chunks) do
      raise ResponseError,
        message: "Transport error: #{reason}",
        kind: :transport,
        reason: reason,
        chunks: chunks
    end

    defp raise_error(%{kind: :unexpected_status, code: code}, chunks) do
      raise ResponseError,
        message: "Unexpected status: #{code}",
        kind: :api,
        reason: :unexpected_status,
        detail: code,
        chunks: chunks
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
          parts = apply(acc.provider, :decode_chunks, [data])

          acc = %{acc | chunks: chunks ++ parts}

          {[parts], acc}

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

    def new(axiom, model, async_request) do
      body_stream =
        Stream.resource(
          fn -> start_fun(axiom.provider, async_request) end,
          &next_fun/1,
          &cleanup/1
        )

      %__MODULE__{
        axiom: axiom,
        model: model,
        async_request: async_request,
        body_stream: body_stream
      }
    end
  end

  @base_headers [
    {"content-type", "application/json"}
  ]

  @spec create(Axiom.t(), model :: String.t(), messages :: list(), opts :: map()) ::
          Completion.t()
  def create(axiom, model, messages, opts \\ %{})
      when is_struct(axiom, Axiom) and is_list(messages) do
    body = apply(axiom.provider, :inputgen, [model, messages, opts])
    auth = apply(axiom.provider, :authgen, [axiom.api_key])

    headers = auth_headers(auth)
    query = auth_query(auth)

    query_text = if query, do: "?" <> URI.encode_query(query), else: ""

    headers = headers ++ axiom.headers ++ @base_headers
    endpoint = apply(axiom.provider, :endpoint, [:completions])

    base_url =
      if is_struct(axiom.base_url, Axiom.UrlBuilder) do
        required = %{}

        required =
          if Enum.member?(axiom.base_url.required, :model) do
            Map.put(required, :model, model)
          else
            %{}
          end

        axiom.base_url.build.(required)
      else
        axiom.base_url
      end

    async_request = fn ->
      :post
      |> Finch.build("#{base_url}#{endpoint}#{query_text}", headers, JSON.encode!(body))
      |> Finch.async_request(axiom.finch_name || Axiom.Finch,
        request_timeout: axiom.request_timeout || :infinity,
        receive_timeout: axiom.receive_timeout || :infinity,
        pool_timeout: 15 * 1000
      )
    end

    Completion.new(axiom, model, async_request)
  end

  defp auth_headers({:header, header}) do
    [header]
  end

  defp auth_headers(_) do
    []
  end

  defp auth_query({:query, params}) do
    params
  end

  defp auth_query(_) do
    nil
  end
end
