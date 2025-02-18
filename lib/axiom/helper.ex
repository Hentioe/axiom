defmodule Axiom.Helper do
  @moduledoc false

  def merge_chunks_content(chunks), do: merge_chunks_delta_content(chunks, "content")

  def merge_chunks_reasoning_content(chunks),
    do: merge_chunks_delta_content(chunks, "reasoning_content")

  def merge_chunks_delta_content(chunks, delta_field) when is_list(chunks) do
    Enum.reduce(chunks, "", fn %{"choices" => choices}, content ->
      content <> merge_choices_delta_field_content(choices, delta_field)
    end)
  end

  defp merge_choices_delta_field_content(choices, field) when is_list(choices) do
    Enum.reduce(choices, "", fn %{"delta" => delta}, content ->
      content <> (delta[field] || "")
    end)
  end

  def chunks_total_tokens(chunks), do: chunks_tokens(chunks, "total_tokens")
  def chunks_prompt_tokens(chunks), do: chunks_tokens(chunks, "prompt_tokens")
  def chunks_completion_tokens(chunks), do: chunks_tokens(chunks, "completion_tokens")

  defp chunks_tokens(chunks, usage_field) when is_list(chunks) do
    Enum.reduce(chunks, 0, fn %{"usage" => usage}, total ->
      total + usage_field_value(usage || %{}, usage_field)
    end)
  end

  defp usage_field_value(usage, field) do
    usage[field] || 0
  end
end
