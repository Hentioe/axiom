defmodule Axiom.Provider.DeepSeek do
  @moduledoc false

  use Axiom.Provider

  @impl true
  def config(_opts) do
    %{
      base_url: "https://api.deepseek.com"
    }
  end
end
