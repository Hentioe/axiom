defmodule Axiom.Provider do
  @moduledoc false

  @type t :: module()
  @type endpoint_name :: :completions
  @type auth_header :: String.t()
  @type auth_value :: String.t()

  @callback config(opts :: keyword) :: map()
  @callback authgen(api_key :: String.t()) ::
              {:header, {auth_header, auth_value}} | {:query, map()}
  @callback endpoint(name :: endpoint_name) :: String.t()
  @callback inputgen(model :: String.t(), messages :: [map], opts :: map) :: map
  @callback decode_chunks(data :: String.t()) :: [map()]
  @callback decoderr(data :: String.t()) :: map()
  @callback errstr(error :: map) :: String.t()
  @callback chunks_total_tokens(chunks :: [map()]) :: non_neg_integer()
  @callback chunks_prompt_tokens(chunks :: [map()]) :: non_neg_integer()
  @callback chunks_completion_tokens(chunks :: [map()]) :: non_neg_integer()
  @callback chunks_content(chunks :: []) :: String.t()
  @callback chunks_reasoning_content(chunks :: []) :: String.t()

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      @spec inputgen(String.t(), [map]) :: map
      def inputgen(model, messages, opts \\ %{}) do
        opts =
          opts
          |> Map.delete(:stream)
          |> Map.delete("stream")

        Map.merge(
          %{
            model: model,
            messages: messages,
            stream: true
          },
          opts
        )
      end

      @spec endpoint(Axiom.Provider.endpoint_name()) :: String.t()
      def endpoint(:completions), do: "/chat/completions"

      @spec authgen(String.t()) ::
              {:header, {Axiom.Provider.auth_header(), Axiom.Provider.auth_value()}}
              | {:query, map()}
      def authgen(api_key), do: {:header, {"authorization", "Bearer #{api_key}"}}

      @spec decode_chunks(String.t()) :: [map()]
      def decode_chunks(data) do
        Axiom.Parsers.ChunksParser.parse_data_chunks(data)
      end

      @spec decoderr(String.t()) :: map()
      def decoderr(data) do
        Axiom.JSON.decode!(data)
      end

      @spec errstr(map) :: String.t()
      def errstr(%{"error" => %{"message" => message}}) do
        message
      end

      def errstr(error) do
        inspect(error)
      end

      @spec chunks_total_tokens([map()]) :: non_neg_integer()
      def chunks_total_tokens(chunks) do
        Axiom.Helper.chunks_total_tokens(chunks)
      end

      @spec chunks_prompt_tokens([map()]) :: non_neg_integer()
      def chunks_prompt_tokens(chunks) do
        Axiom.Helper.chunks_prompt_tokens(chunks)
      end

      @spec chunks_completion_tokens([map()]) :: non_neg_integer()
      def chunks_completion_tokens(chunks) do
        Axiom.Helper.chunks_completion_tokens(chunks)
      end

      @spec chunks_content([map()]) :: String.t()
      def chunks_content(chunks) do
        Axiom.Helper.merge_chunks_content(chunks)
      end

      @spec chunks_reasoning_content([map()]) :: String.t()
      def chunks_reasoning_content(chunks) do
        Axiom.Helper.merge_chunks_reasoning_content(chunks)
      end

      defoverridable inputgen: 3,
                     endpoint: 1,
                     authgen: 1,
                     decode_chunks: 1,
                     decoderr: 1,
                     errstr: 1,
                     chunks_content: 1,
                     chunks_reasoning_content: 1,
                     chunks_total_tokens: 1,
                     chunks_prompt_tokens: 1,
                     chunks_completion_tokens: 1
    end
  end
end
