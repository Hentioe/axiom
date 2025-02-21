defmodule Axiom.Parsers.ChunksParser do
  @moduledoc false

  alias Axiom.JSON

  defmodule ParsingError do
    @moduledoc false

    defexception [:message, :data]
  end

  @spec parse_data_chunks(String.t()) :: [map]
  def parse_data_chunks(data_str) do
    data_str
    |> String.split("\n\n")
    |> Enum.reject(&ignored?/1)
    |> Enum.map(&parse_data_chuhk!/1)
  end

  defp parse_data_chuhk!(<<"data:" <> rest>>) do
    rest |> String.trim() |> JSON.decode!()
  end

  defp parse_data_chuhk!(unknown_data) do
    raise ParsingError, message: "Invalid data chunk", data: unknown_data
  end

  defp ignored?(chunk_text) do
    cond do
      String.trim(chunk_text) == "" -> true
      String.starts_with?(chunk_text, "event:") -> true
      chunk_text == "data: [DONE]" -> true
      true -> false
    end
  end
end
