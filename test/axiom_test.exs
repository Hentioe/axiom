defmodule AxiomTest do
  use ExUnit.Case
  doctest Axiom

  test "greets the world" do
    assert Axiom.hello() == :world
  end
end
