defmodule Axiom.ChatStream do
  @moduledoc false

  use GenServer

  defmodule State do
    @moduledoc false

    defstruct [:name, :api_key, client_store: %{}]

    @type t :: %__MODULE__{
            name: atom(),
            api_key: String.t(),
            client_store: %{Finch.request_ref() => pid()}
          }
  end

  def start_link(name: name, api_key: api_key) do
    GenServer.start_link(__MODULE__, %State{name: name, api_key: api_key}, name: name)
  end

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_call({:send, body}, {pid, _}, state) do
    url = "https://api.siliconflow.cn/v1/chat/completions"

    headers = [
      {"authorization", "Bearer #{state.api_key}"},
      {"content-type", "application/json"}
    ]

    body = Map.put(body, "stream", true)

    ref =
      :post
      |> Finch.build(url, headers, JSON.encode!(body))
      |> Finch.async_request(Axiom.Chat)

    {:reply, ref, put_client(state, ref, pid)}
  end

  @impl true
  def handle_info({_ref, {:status, 200}}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({_ref, {:headers, _}}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({ref, {:data, <<"data: [DONE]\n\n">>}}, state) do
    caller = Map.get(state.client_store, ref)
    Process.send(caller, :done, [])

    {:noreply, state}
  end

  @impl true
  def handle_info({ref, {:data, <<"data:" <> rest>>}}, state) do
    caller = Map.get(state.client_store, ref)

    # 解码后发送给调用端
    # JSON 模块每秒可以执行数万次解码，故忽略对 GenServer 的负面影响
    Process.send(caller, {:data, JSON.decode!(rest)}, [])

    {:noreply, state}
  end

  @impl true
  def handle_info({ref, {:data, data}}, state) do
    caller = Map.get(state.client_store, ref)

    Process.send(caller, {:data, data}, [])

    {:noreply, state}
  end

  @impl true
  def handle_info({ref, :done}, state) do
    {:noreply, remove_client(state, ref)}
  end

  defp put_client(state, ref, caller) do
    Map.update(state, :client_store, %{}, fn store -> Map.put(store, ref, caller) end)
  end

  defp remove_client(state, ref) do
    Map.update(state, :client_store, %{}, fn store -> Map.delete(store, ref) end)
  end
end
