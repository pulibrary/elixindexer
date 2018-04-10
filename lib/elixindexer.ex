defmodule Elixindexer do
  def parse_records(file_name) do
    {:ok, handle} = File.open(file_name, read_ahead: 512*1024)
    output = MarcParser.parse_marc(handle)
    |> Flow.partition
    |> Flow.map(&solrize/1)
    |> Enum.to_list
  end

  def solrize(%MarcParser.Record{fields: fields}) do
    fields
    |> Enum.reduce(%{}, &build_solr_field/2)
  end

  def build_solr_field({"001", %MarcParser.ControlField{value: value}}, acc) do
    acc
    |> Map.put(:id, value)
  end

  def build_solr_field({"245", subfield}, acc) do
    title = subfield
            |> get_subfields("abcfghknps")
            |> Enum.join(" ")
    acc
    |> Map.put(:title, title)
  end

  def build_solr_field(_, acc) do
    acc
  end

  def get_subfields(%MarcParser.DataField{subfields: subfields}, fields) do
    fields
    |> String.graphemes()
    |> Enum.map(&get_subfield_value(subfields[&1]))
    |> Enum.filter(fn x -> x != nil end)
  end

  def get_subfield_value(%MarcParser.SubField{value: value}) do
    value
  end

  def get_subfield_value(_) do
    nil
  end
end
