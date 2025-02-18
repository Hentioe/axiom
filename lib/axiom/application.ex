defmodule Axiom.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  require Logger

  use Application

  @impl true
  def start(_type, _args) do
    # Check if the json_adapter is implemented
    if adapter = Axiom.json_adapter() do
      ^adapter = Code.ensure_loaded!(adapter)

      if !function_exported?(adapter, :encode!, 1) do
        Logger.error("JSON adapter #{adapter} does not implement `encode!/1`")
      end

      if !function_exported?(adapter, :decode!, 1) do
        Logger.error("JSON adapter #{adapter} does not implement `decode!/1`")
      end
    else
      Logger.error("No JSON adapter configured")
    end

    children = [
      # Starts a worker by calling: Axiom.Worker.start_link(arg)
      # {Axiom.Worker, arg}
      {Finch, name: Axiom.Finch}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Axiom.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
