defmodule Axiom do
  @moduledoc false

  defstruct [
    :provider,
    :base_url,
    :api_key,
    :request_timeout,
    :receive_timeout,
    :finch_name,
    headers: []
  ]

  @type t :: %__MODULE__{
          provider: module(),
          base_url: String.t(),
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

  @spec with_base_url(t(), String.t()) :: t()
  def with_base_url(axiom, base_url) when is_struct(axiom, __MODULE__) do
    %{axiom | base_url: base_url}
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

  @doc """
  Returns `true` if term is a request_ref, otherwise returns `false`.

  ## Examples

  iex> Axiom.is_request_ref({Finch.HTTP1.Pool, self()})
  true
  """
  defguard is_request_ref(term)
           when is_tuple(term) and
                  tuple_size(term) == 2 and
                  elem(term, 0) in [Finch.HTTP1.Pool, Finch.HTTP2.Pool] and
                  is_pid(elem(term, 1))
end
