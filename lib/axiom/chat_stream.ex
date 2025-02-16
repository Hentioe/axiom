defmodule Axiom.ChatStream do
  @moduledoc false

  use GenServer

  defmodule State do
    @moduledoc false

    defstruct [:name, :provider, :api_url, :api_key, headers: [], caller_store: %{}]

    @type t :: %__MODULE__{
            name: String.t(),
            provider: module(),
            api_url: String.t(),
            api_key: String.t(),
            headers: Finch.Request.headers(),
            caller_store: %{Finch.request_ref() => pid()}
          }
  end

  def new(args) do
    {__MODULE__, args}
  end

  def start_link(opts) do
    name = Keyword.get(opts, :name)
    stream_name = String.to_atom(Axiom.stream_name(name))

    GenServer.start_link(
      __MODULE__,
      %State{
        name: name,
        provider: Keyword.get(opts, :provider),
        api_url: Keyword.get(opts, :api_url),
        api_key: Keyword.get(opts, :api_key),
        headers: Keyword.get(opts, :headers, [])
      },
      name: stream_name
    )
  end

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_call({:send, body}, {pid, _}, state) do
    headers =
      [
        {"authorization", "Bearer #{state.api_key}"},
        {"content-type", "application/json"}
      ] ++ state.headers

    ref =
      :post
      |> Finch.build(state.api_url, headers, JSON.encode!(body))
      |> Finch.async_request(String.to_atom(Axiom.finch_name(state.name)))

    {:reply, ref, put_caller(state, ref, pid)}
  end

  @impl true
  def handle_call({:inputgen, model, messages, opts}, _from, state) do
    body = apply(state.provider, :inputgen, [model, messages, opts])

    {:reply, body, state}
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

    {:noreply, remove_caller(state, ref)}
  end

  @impl true
  def handle_info({ref, {:data, data}}, state) do
    caller_send(state, ref, {:data, data})

    {:noreply, state}
  end

  @impl true
  def handle_info({ref, :done}, state) do
    caller_send(state, ref, :done)

    {:noreply, remove_caller(state, ref)}
  end

  @impl true
  def handle_info({ref, {:status, 401}}, state) do
    caller_send(state, ref, {:error, 401})

    {:noreply, remove_caller(state, ref)}
  end

  def handle_info({ref, {:error, error}}, state) when is_struct(error, Mint.TransportError) do
    caller_send(state, ref, {:error, error.reason})

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
