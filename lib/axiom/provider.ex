defmodule Axiom.Provider do
  @moduledoc false

  @callback config(opts :: keyword) :: keyword
  @callback inputgen(model :: String.t(), messages :: [map], opts :: map) :: map

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

      defoverridable inputgen: 3
    end
  end
end
