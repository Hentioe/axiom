defmodule Axiom.UrlBuilder do
  @moduledoc false

  defstruct [:build, required: []]

  @type t :: %__MODULE__{build: ([any()] -> String.t()), required: [atom()]}
end
