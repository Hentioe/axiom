defmodule Axiom.Provider.DeepSeek do
  @moduledoc false

  use Axiom.Provider

  def config(_opts) do
    %{
      base_url: "https://api.deepseek.com/v1"
    }
  end
end
