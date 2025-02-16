defmodule Axiom.Chat do
  @moduledoc false

  def stream_complete(name, model, messages, opts \\ %{}) when is_list(messages) do
    server =
      name
      |> Axiom.stream_name()
      |> String.to_atom()

    body = GenServer.call(server, {:inputgen, model, messages, opts})

    GenServer.call(server, {:send, body})
  end
end
