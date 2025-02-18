defmodule Axiom.Provider.XAi do
  @moduledoc false

  use Axiom.Provider

  def config(_opts) do
    %{
      base_url: "https://api.x.ai/v1"
    }
  end
end
