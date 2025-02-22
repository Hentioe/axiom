defmodule Axiom.Provider.Anthropic do
  @moduledoc false

  use Axiom.Provider

  @impl true
  def config(opts) do
    headers =
      if version = Keyword.get(opts, :version) do
        [{"anthropic-version", version}]
      else
        []
      end

    %{
      base_url: "https://api.anthropic.com/v1",
      headers: headers
    }
  end

  @impl true
  def endpoint(:completions), do: "/messages"

  @impl true
  def authgen(api_key), do: {:header, {"x-api-key", api_key}}

  # Legacy completion API parameters
  # @impl true
  # def inputgen(model, messages, opts) do
  #   prompt = messages_to_prompt(messages)

  #   opts =
  #     opts
  #     |> Map.delete(:stream)
  #     |> Map.delete("stream")

  #   Map.merge(
  #     %{
  #       model: model,
  #       prompt: prompt
  #     },
  #     opts
  #   )
  # end

  # defp messages_to_prompt(messages) when is_list(messages) do
  #   Enum.map_join(messages, "", &message_to_prompt/1)
  # end

  # defp message_to_prompt(%{role: role, content: content}) do
  #   role =
  #     case to_string(role) do
  #       "system" -> "Human"
  #       "user" -> "Human"
  #       "assistant" -> "Assistant"
  #     end

  #   "\n\n#{role}: #{content}"
  # end
end
