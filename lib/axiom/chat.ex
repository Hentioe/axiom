defmodule Axiom.Chat do
  @moduledoc false

  def stream_complete(stream_server, model, messages) when is_list(messages) do
    body = GenServer.call(stream_server, {:gen_input_body, model, messages})

    GenServer.call(stream_server, {:send, body})
  end
end
