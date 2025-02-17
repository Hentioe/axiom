defmodule Axiom do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    name = Keyword.get(opts, :name)

    Supervisor.start_link(__MODULE__, opts, name: String.to_atom(sup_name(name)))
  end

  @impl true
  def init(init_arg) do
    name = Keyword.get(init_arg, :name)
    passed_finch_name = Keyword.get(init_arg, :finch_name)

    finch_name =
      if passed_finch_name do
        passed_finch_name
      else
        String.to_atom(finch_name(name))
      end

    children =
      if passed_finch_name do
        []
      else
        finch_conn_opts =
          if proxy = Keyword.get(init_arg, :proxy, []) do
            [:proxy, proxy]
          else
            []
          end

        [
          {Finch,
           name: finch_name,
           pools: [
             default: [conn_opts: finch_conn_opts]
           ]}
        ]
      end

    chat_stream_opts =
      Keyword.merge(init_arg, name: String.to_atom(stream_name(name)), finch_name: finch_name)

    children =
      children ++
        [
          Axiom.ChatStream.new(chat_stream_opts)
        ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def sup_name(name) do
    "axiom_sup." <> name
  end

  def stream_name(name) do
    sup_name(name) <> ".chat_stream"
  end

  def finch_name(name) do
    sup_name(name) <> ".finch"
  end

  @spec new(module(), String.t(), String.t(), Keyword.t()) :: Supervisor.child_spec()
  def new(provider, name, api_key, opts \\ []) do
    # todo: 检查 provider 是否实现了 Axiom.Provider 协议
    args =
      [
        name: name,
        provider: provider,
        api_key: api_key
      ]

    config =
      provider
      |> apply(:config, [opts])
      |> Keyword.delete(:name)
      |> Keyword.delete(:provider)
      |> Keyword.delete(:api_key)

    args =
      args
      |> Keyword.merge(config)
      |> Keyword.merge(
        finch_name: Keyword.get(opts, :finch_name),
        proxy: Keyword.get(opts, :proxy),
        request_timeout: Keyword.get(opts, :request_timeout, 15_000),
        receive_timeout: Keyword.get(opts, :receive_timeout, 30_000)
      )

    Supervisor.child_spec({__MODULE__, args}, id: String.to_atom(name))
  end
end
