defmodule Axiom.Provider.Siliconflow do
  @moduledoc false

  use Axiom.Provider

  def config(_opts) do
    [
      api_url: "https://api.siliconflow.cn/v1/chat/completions"
    ]
  end
end
