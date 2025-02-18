defmodule Axiom do
  @moduledoc false

  defstruct [
    :provider,
    :api_url,
    :api_key,
    :request_timeout,
    :receive_timeout,
    :finch_name,
    headers: []
  ]

  @type t :: %__MODULE__{
          provider: module(),
          api_url: String.t(),
          api_key: String.t(),
          request_timeout: timeout,
          receive_timeout: timeout,
          finch_name: atom,
          headers: Finch.Request.headers()
        }

  @spec build(module(), String.t(), keyword()) :: t()
  def build(provider, api_key, opts \\ []) do
    args =
      %{
        provider: provider,
        api_key: api_key
      }

    config =
      provider
      |> apply(:config, [opts])
      |> Map.delete(:provider)
      |> Map.delete(:api_key)

    struct(__MODULE__, Map.merge(args, config))
  end

  @spec with_api_url(t(), String.t()) :: t()
  def with_api_url(axiom, api_url) when is_struct(axiom, __MODULE__) do
    %{axiom | api_url: api_url}
  end

  @spec with_timeout(t(), timeout(), timeout()) :: t()
  def with_timeout(axiom, request_timeout, receive_timeout) when is_struct(axiom, __MODULE__) do
    %{axiom | request_timeout: request_timeout, receive_timeout: receive_timeout}
  end

  @spec with_finch_name(t(), atom()) :: t()
  def with_finch_name(axiom, finch_name) when is_struct(axiom, __MODULE__) do
    %{axiom | finch_name: finch_name}
  end

  @spec with_headers(t(), Finch.Request.headers()) :: t()
  def with_headers(axiom, headers) do
    %{axiom | headers: axiom.headers ++ headers}
  end

  def json_adapter do
    Application.get_env(:axiom, :json_adapter)
  end
end
