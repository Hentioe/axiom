defmodule Axiom.Provider do
  @moduledoc false

  @callback config(opts :: keyword) :: keyword
  @callback streamized_body(body :: map) :: map
  @callback gen_input_body(model :: String.t(), messages :: [map]) :: map

  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      @spec streamized_body(map) :: map
      def streamized_body(body) do
        Map.put(body, :stream, true)
      end

      @spec gen_input_body(String.t(), [map]) :: map
      def gen_input_body(model, messages) do
        %{
          "model" => model,
          "messages" => messages
        }
      end

      defoverridable streamized_body: 1
    end
  end
end
