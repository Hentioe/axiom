defmodule Axiom.Parsers.StreamDataParser do
  @moduledoc false

  @ignored_data ["", "data: [DONE]"]

  @spec parse(String.t()) :: [map]
  def parse(data_str) do
    data_str
    |> String.split("\n\n")
    |> Enum.reject(&data_ignored?/1)
    |> Enum.map(&parse_one!/1)
  end

  defp parse_one!(<<"data:" <> rest>>) do
    rest |> String.trim() |> JSON.decode!()
  end

  defp data_ignored?(one_data) do
    Enum.member?(@ignored_data, String.trim(one_data))
  end
end
