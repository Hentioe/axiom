defmodule Axiom.Helper do
  @moduledoc false

  def merge_data_content(data) when is_list(data) do
    Enum.reduce(data, "", fn %{"choices" => choices}, content ->
      content <> merge_choices_content(choices)
    end)
  end

  defp merge_choices_content(choices) when is_list(choices) do
    Enum.reduce(choices, "", fn %{"delta" => delta}, content ->
      content <> delta["content"]
    end)
  end
end
