defmodule Axiom.Provider.Volcengine do
  @moduledoc false

  use Axiom.Provider

  @impl true
  def config(opts) do
    region = Keyword.get(opts, :region, "cn-beijing")
    base_url = "https://ark.#{region}.volces.com/api/v3"

    %{
      base_url: base_url
    }
  end
end
