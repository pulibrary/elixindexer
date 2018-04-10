defmodule ElixindexerTest do
  use ExUnit.Case
  doctest Elixindexer

  test "greets the world" do
    assert Elixindexer.hello() == :world
  end

  test "parse_records" do
    records = Elixindexer.parse_records("small_set.mrc")
    assert length(records) == 31
    # record = hd(records)
    # assert(%{id: "345682"} = record)
    # assert(%{title: "Opportunity in crisis : money and power in world politics 1986-88 / Michael M. White."} = record)
  end
end
