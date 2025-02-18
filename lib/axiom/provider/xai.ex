defmodule Axiom.Provider.XAi do
  @moduledoc false

  use Axiom.Provider

  def config(_opts) do
    %{
      api_url: "https://api.x.ai/v1/chat/completions"
    }
  end
end
