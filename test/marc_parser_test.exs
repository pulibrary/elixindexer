defmodule MarcParserTest do
  use ExUnit.Case

  test "parse_records" do
    {:ok, handle} = File.open("small_set.mrc", read_ahead: 512*1024)
    record = MarcParser.parse_marc(handle) |> Stream.take(1) |> Enum.to_list |> hd
    %{fields: fields} = record
    %{"500" => five_hundred_fields} = fields
    assert length(five_hundred_fields) == 2
    field = hd(five_hundred_fields)
    assert %{subfields: %{"a" => [%{value: "International conference proceedings."}]}} = field
    assert field.indicator1 == " "
    assert field.indicator2 == " "
    assert %{"245" => [%{indicator1: "1", indicator2: "0"}]} = fields
  end
end
