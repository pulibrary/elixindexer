defmodule ElixindexerTest do
  use ExUnit.Case
  doctest Elixindexer

  test "parse_records" do
    records = Elixindexer.parse_records("small_set.mrc")
    assert length(records) == 31
    record = hd(records)
    assert(%{id: "6000001"} = record)
    assert(%{title: "Bach und die deutsche Tradition des Komponierens : Wirklichkeit und Ideologie ; Festschrift Martin Geck zum 70. Geburtstag ; Bericht über das 6. Dortmunder Bach-Symposion 2006 / herausgegeben von Reinmar Emans und Wolfram Steinbeck."} = record)
  end
end
