defmodule Axiom.Provider.Google do
  @moduledoc false

  use Axiom.Provider

  alias Axiom.UrlBuilder

  @impl true
  def config(opts) do
    version = Keyword.get(opts, :version, "v1beta")
    base_url = "https://generativelanguage.googleapis.com/#{version}/models"

    build = fn %{model: model} ->
      "#{base_url}/#{model}:"
    end

    builder = %UrlBuilder{
      build: build,
      required: [:model]
    }

    %{
      base_url: builder
    }
  end

  @impl true
  def authgen(api_key) do
    # todo: Separate other parameters from authgen
    {:query, %{"key" => api_key, "alt" => "sse"}}
  end

  @impl true
  def endpoint(:completions) do
    "streamGenerateContent"
  end

  @impl true
  def inputgen(_model, messages, opts) do
    base_params = %{
      contents: messages_to_contents(messages)
    }

    Map.merge(base_params, opts)
  end

  defp messages_to_contents(messages) do
    Enum.map(messages, &message_to_content/1)
  end

  defp message_to_content(%{role: role, content: content}) do
    role =
      case role do
        :user -> :user
        :system -> :user
        :assistant -> :model
      end

    %{
      role: role,
      parts: [
        %{
          text: content
        }
      ]
    }
  end

  @impl true
  def chunks_content(chunks) do
    merge_chunks_content(chunks)
  end

  @impl true
  def chunks_reasoning_content(_chunks) do
    # eng: Google does not provide reasoning content in the API
    # https://ai.google.dev/gemini-api/docs/thinking
    ""
  end

  # Response chunk example:
  # %{
  #   "candidates" => [
  #     %{
  #       "content" => %{"parts" => [%{"text" => "231\n"}], "role" => "model"},
  #       "finishReason" => "STOP"
  #     }
  #   ],
  #   "modelVersion" => "gemini-1.5-flash",
  #   "usageMetadata" => %{
  #     "candidatesTokenCount" => 5,
  #     "candidatesTokensDetails" => [%{"modality" => "TEXT", "tokenCount" => 5}],
  #     "promptTokenCount" => 43,
  #     "promptTokensDetails" => [%{"modality" => "TEXT", "tokenCount" => 43}],
  #     "totalTokenCount" => 48
  #   }
  # }

  defp merge_chunks_content(chunks) do
    Enum.reduce(chunks, "", fn chunk, acc ->
      acc <> merge_chunk_content(chunk)
    end)
  end

  defp merge_chunk_content(chunk) do
    Enum.reduce(chunk["candidates"], "", fn candidate, acc ->
      acc <> parts_text(candidate["content"]["parts"])
    end)
  end

  defp parts_text(parts) do
    Enum.reduce(parts, "", fn part, acc ->
      acc <> part["text"]
    end)
  end

  @impl true
  def chunks_total_tokens(chunks) do
    chunks |> List.last() |> candidate_tokens("totalTokenCount")
  end

  @impl true
  def chunks_prompt_tokens(chunks) do
    chunks |> List.last() |> candidate_tokens("promptTokenCount")
  end

  @impl true
  def chunks_completion_tokens(chunks) do
    chunks |> List.last() |> candidate_tokens("candidatesTokenCount")
  end

  defp candidate_tokens(candidate, field) do
    candidate["usageMetadata"][field]
  end

  # Response error body example:
  # %{
  #   "error" => %{
  #     "code" => 400,
  #     "details" => [
  #       %{
  #         "@type" => "type.googleapis.com/google.rpc.ErrorInfo",
  #         "domain" => "googleapis.com",
  #         "metadata" => %{"service" => "generativelanguage.googleapis.com"},
  #         "reason" => "API_KEY_INVALID"
  #       },
  #       %{
  #         "@type" => "type.googleapis.com/google.rpc.LocalizedMessage",
  #         "locale" => "en-US",
  #         "message" => "API key not valid. Please pass a valid API key."
  #       }
  #     ],
  #     "message" => "API key not valid. Please pass a valid API key.",
  #     "status" => "INVALID_ARGUMENT"
  #   }
  # }
end
