defmodule Axiom.Chat do
  @moduledoc false

  # 消息的例子：
  # [
  #   %{
  #     "role" => "user",
  #     "content" => "你好"
  #   }
  # ]

  def stream_complete(stream_server, model, messages) when is_list(messages) do
    body = %{
      "model" => model,
      "messages" => messages
    }

    GenServer.call(stream_server, {:send, body})
  end
end
