defmodule Axiom.Helper do
  @moduledoc false

  def merge_chunks_content(chunks) when is_list(chunks) do
    Enum.reduce(chunks, "", fn %{"choices" => choices}, content ->
      content <> merge_choices_content(choices)
    end)
  end

  defp merge_choices_content(choices) when is_list(choices) do
    Enum.reduce(choices, "", fn %{"delta" => delta}, content ->
      content <> (delta["content"] || "")
    end)
  end
end
