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
    finch_name = String.to_atom(finch_name(name))

    children = [
      {Finch, name: finch_name},
      Axiom.ChatStream.new(init_arg)
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

  @spec new(module(), String.t(), String.t(), Keyword.t()) :: {__MODULE__, Keyword.t()}
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

    args = Keyword.merge(args, config)

    {__MODULE__, args}
  end
end
