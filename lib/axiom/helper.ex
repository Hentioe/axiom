defmodule Axiom.Helper do
  @moduledoc false

  def merge_chunks_content(chunks) when is_list(chunks) do
    Enum.reduce(chunks, "", fn %{"choices" => choices}, content ->
      content <> merge_choices_delta_field(choices, "content")
    end)
  end

  def merge_chunks_reasoning_content(chunks) when is_list(chunks) do
    Enum.reduce(chunks, "", fn %{"choices" => choices}, content ->
      content <> merge_choices_delta_field(choices, "reasoning_content")
    end)
  end

  defp merge_choices_delta_field(choices, field) when is_list(choices) do
    Enum.reduce(choices, "", fn %{"delta" => delta}, content ->
      content <> (delta[field] || "")
    end)
  end
end
