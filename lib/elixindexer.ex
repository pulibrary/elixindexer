require IEx
defmodule Elixindexer do
  def parse_records(file_name) do
    {:ok, handle} = File.open(file_name)
    result = MarcParser.parse_marc(handle)
             |> Enum.map(&solrize/1)
  end

  def solrize(%MarcParser.Record{fields: fields}) do
    id = fields["001"].value
    title = fields["245"]
            |> get_subfields("abcfghknps")
            |> Enum.join(" ")
    %{
      id: id,
      title: title
    }
  end

  def get_subfields(%MarcParser.DataField{subfields: subfields}, fields) do
    fields
    |> String.graphemes
    |> Enum.map(&get_subfield_value(subfields[&1]))
    |> Enum.filter(fn (x) -> x != nil end)
  end

  def get_subfield_value(%MarcParser.SubField{value: value}) do
    value
  end

  def get_subfield_value(_) do
    nil
  end
end
