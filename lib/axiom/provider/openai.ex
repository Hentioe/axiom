defmodule Axiom.Provider.OpenAi do
  @moduledoc false

  use Axiom.Provider

  @impl true
  def config(_opts) do
    %{
      base_url: "https://api.openai.com/v1"
    }
  end
end
