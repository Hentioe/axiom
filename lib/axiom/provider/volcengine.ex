defmodule Axiom.Provider.Volcengine do
  @moduledoc false

  use Axiom.Provider

  @impl true
  def config(opts) do
    region = Keyword.get(opts, :region, "cn-beijing")
    base_url = "https://ark.#{region}.volces.com/api/v3"

    %{
      base_url: base_url
    }
  end

  @impl true
  def inputgen(model, messages, opts) do
    opts =
      opts
      |> Map.delete(:stream)
      |> Map.delete("stream")

    Map.merge(
      %{
        model: model,
        messages: messages,
        stream: true,
        stream_options: %{
          # If this parameter is not present, the token usage cannot be obtained
          include_usage: true
        }
      },
      opts
    )
  end

  # Response error body example:
  # %{
  #   "error" => %{
  #     "code" => "InvalidEndpointOrModel.NotFound",
  #     "message" => "The model or endpoint ep-xxxx-xxx does not exist or you do not have access to it. Request id: 021740173163661320f9aadc50dbf6687c3b1e9f9e54ac6d067ad",
  #     "param" => "",
  #     "type" => "NotFound"
  #   }
  # }

  @impl true
  def errstr(%{"error" => %{"message" => message}}) do
    message
  end
end
