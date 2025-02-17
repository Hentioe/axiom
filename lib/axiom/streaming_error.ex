defmodule Axiom.StreamingError do
  @moduledoc false

  defexception [:message, :reason, chunks: []]
end
