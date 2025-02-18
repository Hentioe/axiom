defmodule Axiom.Provider.DeepSeek do
  @moduledoc false

  use Axiom.Provider

  def config(_opts) do
    %{
      api_url: "https://api.deepseek.com/v1/chat/completions"
    }
  end
end
