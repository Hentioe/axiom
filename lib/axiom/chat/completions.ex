defmodule Axiom.Chat.Completions do
  @moduledoc false

  defmodule Created do
    @moduledoc false

    require Logger

    alias Axiom.StreamingError

    defstruct [:ref, :body_stream]

    @type t :: %__MODULE__{ref: Finch.request_ref(), body_stream: Enumerable.t()}

    defp mapping_receive(ref) do
      receive do
        {^ref, {:status, 200}} ->
          :cont

        {^ref, {:headers, _}} ->
          :cont

        {^ref, {:data, <<"data: [DONE]\n\n">>}} ->
          :cont

        {^ref, :done} ->
          :done

        {^ref, {:data, data}} ->
          {:data, data}

        {^ref, {:status, 401}} ->
          {:error, 401}

        {^ref, {:error, error}} when is_struct(error, Mint.TransportError) ->
          {:error, error.reason}

        {^ref, msg} ->
          Logger.warning("Received unknown Finch response message: #{inspect(msg)}")

          :cont
      end
    end

    defp build_start_fun(ref) do
      fn ->
        case mapping_receive(ref) do
          {:data, data} ->
            [data]

          :cont ->
            []

          :done ->
            []

          {:error, reason} ->
            raise StreamingError, message: to_string(reason), reason: reason
        end
      end
    end

    defp build_next_fun(ref) do
      fn chunks ->
        case mapping_receive(ref) do
          {:data, data} ->
            {[data], chunks ++ [data]}

          :cont ->
            {[], chunks}

          :done ->
            {:halt, chunks}

          {:error, reason} ->
            raise StreamingError, message: to_string(reason), reason: reason, chunks: chunks
        end
      end
    end

    defp cleanup(_chunks), do: :cleanup

    def new(ref) do
      body_stream = Stream.resource(build_start_fun(ref), build_next_fun(ref), &cleanup/1)

      %__MODULE__{ref: ref, body_stream: body_stream}
    end
  end

  @spec create(Axiom.t(), model :: String.t(), messages :: list(), opts :: map()) :: Created.t()
  def create(axiom, model, messages, opts \\ %{})
      when is_struct(axiom, Axiom) and is_list(messages) do
    body = apply(axiom.provider, :inputgen, [model, messages, opts])

    headers =
      [
        {"authorization", "Bearer #{axiom.api_key}"},
        {"content-type", "application/json"}
      ] ++ axiom.headers

    ref =
      :post
      |> Finch.build(axiom.api_url, headers, JSON.encode!(body))
      |> Finch.async_request(axiom.finch_name || Axiom.Finch,
        request_timeout: axiom.request_timeout || 15_000,
        receive_timeout: axiom.receive_timeout || 30_000
      )

    Created.new(ref)
  end
end
