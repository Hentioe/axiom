defmodule Axiom.Provider.Siliconflow do
  @moduledoc false

  use Axiom.Provider

  def config(_opts) do
    %{
      base_url: "https://api.siliconflow.cn/v1"
    }
  end
end
