defmodule Axiom.Parsers.ChunksParser do
  @moduledoc false

  alias Axiom.JSON

  defmodule ParsingError do
    @moduledoc false

    defexception [:message, :data]
  end

  @ignored_data ["", "data: [DONE]"]

  @spec parse_data_chunks(String.t()) :: [map]
  def parse_data_chunks(data_str) do
    data_str
    |> String.split("\n\n")
    |> Enum.reject(&data_ignored?/1)
    |> Enum.map(&parse_data_one!/1)
  end

  defp parse_data_one!(<<"data:" <> rest>>) do
    rest |> String.trim() |> JSON.decode!()
  end

  defp parse_data_one!(unknown_data) do
    raise ParsingError, message: "Invalid data chunk", data: unknown_data
  end

  defp data_ignored?(one_data) do
    Enum.member?(@ignored_data, String.trim(one_data))
  end
end
