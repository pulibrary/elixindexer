defmodule ElixindexerTest do
  use ExUnit.Case
  doctest Elixindexer

  test "parse_records" do
    records = Elixindexer.parse_records("small_set.mrc")
    assert length(records) == 31
    record = records |> Enum.find(fn(x) -> x.id == "6000001" end)
    assert record.id == "6000001"
    assert record.title_display == "Bach und die deutsche Tradition des Komponierens : Wirklichkeit und Ideologie ; Festschrift Martin Geck zum 70. Geburtstag ; Bericht über das 6. Dortmunder Bach-Symposion 2006 / herausgegeben von Reinmar Emans und Wolfram Steinbeck."
    assert record.author_display == ["Dortmunder Bach-Symposion (6th : 2006)"]
    assert record.author_s == ["Dortmunder Bach-Symposion (6th : 2006)",
                                "Emans, Reinmar",
                                "Steinbeck, Wolfram"]
    assert record.subject_display == [
                                "Bach, Johann Sebastian, 1685-1750—Congresses",
                                "Bach, Johann Sebastian, 1685-1750—Influence—Congresses"
                              ]
    assert record.format == ["Book"]
  end
end
