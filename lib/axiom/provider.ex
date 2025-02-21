defmodule Axiom.Provider do
  @moduledoc false

  @type t :: module()
  @type endpoint_name :: :completions
  @type auth_header :: String.t()
  @type auth_value :: String.t()

  @callback config(opts :: keyword) :: map()
  @callback inputgen(model :: String.t(), messages :: [map], opts :: map) :: map
  @callback endpoint(name :: endpoint_name) :: String.t()
  @callback authgen(api_key :: String.t()) :: {auth_header, auth_value}
  @callback decoderr(data :: String.t()) :: map()

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

      @spec authgen(String.t()) :: {Axiom.Provider.auth_header(), Axiom.Provider.auth_value()}
      def authgen(api_key), do: {"authorization", "Bearer #{api_key}"}

      @spec decoderr(String.t()) :: map()
      def decoderr(data) do
        Axiom.JSON.decode!(data)
      end

      defoverridable inputgen: 3, endpoint: 1, authgen: 1, decoderr: 1
    end
  end
end
