defmodule Axiom.JSON do
  @moduledoc false

  defp adapter, do: Axiom.json_adapter()

  def encode!(data) do
    apply(adapter(), :encode!, [data])
  end

  def decode!(data) do
    apply(adapter(), :decode!, [data])
  end
end
