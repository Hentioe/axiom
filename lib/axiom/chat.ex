defmodule Axiom.Chat do
  @moduledoc false

  def stream_complete(name, model, messages) when is_list(messages) do
    server = name |> Axiom.stream_name() |> String.to_atom()
    body = GenServer.call(server, {:gen_input_body, model, messages})

    GenServer.call(server, {:send, body})
  end
end
