defmodule Axiom.ChatStream do
  @moduledoc false

  use GenServer

  defmodule State do
    @moduledoc false

    defstruct [:name, :api_url, :api_key, caller_store: %{}]

    @type t :: %__MODULE__{
            name: atom(),
            api_url: String.t(),
            api_key: String.t(),
            caller_store: %{Finch.request_ref() => pid()}
          }
  end

  def spec(provider, name, api_key, opts \\ []) do
    {__MODULE__, _spec(provider, name, api_key, opts)}
  end

  def _spec(:siliconflow, name, api_key, _opts) do
    [name: name, api_url: "https://api.siliconflow.cn/v1/chat/completions", api_key: api_key]
  end

  def _spec(:volcengine, name, api_key, opts) do
    region = Keyword.get(opts, :region, "cn-beijing")
    api_url = "https://ark.#{region}.volces.com/api/v3/chat/completions"

    [name: name, api_url: api_url, api_key: api_key]
  end

  def start_link(opts) do
    name = Keyword.get(opts, :name)
    api_url = Keyword.get(opts, :api_url)
    api_key = Keyword.get(opts, :api_key)

    GenServer.start_link(__MODULE__, %State{name: name, api_url: api_url, api_key: api_key},
      name: name
    )
  end

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_call({:send, body}, {pid, _}, state) do
    headers = [
      {"authorization", "Bearer #{state.api_key}"},
      {"content-type", "application/json"}
    ]

    body = Map.put(body, "stream", true)

    ref =
      :post
      |> Finch.build(state.api_url, headers, JSON.encode!(body))
      |> Finch.async_request(Axiom.Chat)

    {:reply, ref, put_caller(state, ref, pid)}
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
    caller_send(state, ref, :done)

    {:noreply, state}
  end

  @impl true
  def handle_info({ref, {:data, <<"data:" <> rest>>}}, state) do
    # 解码后发送给调用端（JSON 模块每秒足以完成数万次解码，可忽略对 GenServer 的负面影响）
    caller_send(state, ref, {:data, JSON.decode!(rest)})

    {:noreply, state}
  end

  @impl true
  def handle_info({ref, {:data, data}}, state) do
    caller_send(state, ref, {:data, data})

    {:noreply, state}
  end

  @impl true
  def handle_info({ref, :done}, state) do
    {:noreply, remove_caller(state, ref)}
  end

  @impl true
  def handle_info({ref, {:status, 401}}, state) do
    caller_send(state, ref, {:error, 401})

    {:noreply, remove_caller(state, ref)}
  end

  defp caller_send(state, ref, message) do
    case Map.get(state.caller_store, ref) do
      nil ->
        :ignored

      caller when is_pid(caller) ->
        Process.send(caller, message, [])
    end
  end

  defp put_caller(state, ref, caller) do
    update_caller_store(state, fn store -> Map.put(store, ref, caller) end)
  end

  defp remove_caller(state, ref) do
    update_caller_store(state, fn store -> Map.delete(store, ref) end)
  end

  defp update_caller_store(state, update_fun) do
    Map.update(state, :caller_store, %{}, update_fun)
  end
end
