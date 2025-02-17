defmodule Axiom.Provider.Volcengine do
  @moduledoc false

  use Axiom.Provider

  @impl true
  def config(opts) do
    region = Keyword.get(opts, :region, "cn-beijing")
    api_url = "https://ark.#{region}.volces.com/api/v3/chat/completions"

    %{
      api_url: api_url
    }
  end
end
