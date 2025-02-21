defmodule Axiom.Provider.Aliyun do
  @moduledoc false

  use Axiom.Provider

  @impl true
  def config(_opts) do
    %{
      base_url: "https://dashscope.aliyuncs.com/compatible-mode/v1"
    }
  end
end
