defmodule Axiom.Provider.TencentCloud do
  @moduledoc false

  use Axiom.Provider

  @impl true
  def config(opts) do
    region = Keyword.get(opts, :region, "ap-shanghai")

    [
      api_url: "https://api.lkeap.cloud.tencent.com/v1/chat/completions",
      headers: [
        {"X-TC-Region", region}
      ]
    ]
  end
end
