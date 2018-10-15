defmodule Elixindexer do
  def parse_records(file_name) when is_binary(file_name) do
    {:ok, handle} = File.open(file_name, read_ahead: 512*1024)
    output = parse_records(handle)
    handle |> File.close
    output
  end

  def parse_records(handle) do
    MarcParser.parse_marc(handle)
    |> Flow.partition
    |> Flow.map(&solrize/1)
    |> Enum.sort
  end

  defp solrize(%MarcParser.Record{fields: fields}) do
    fields
    |> Enum.reduce(%{}, &build_solr_field/2)
  end

  defp build_solr_field({"001", [%MarcParser.ControlField{value: value}]}, acc) do
    acc
    |> Map.put(:id, value)
  end

  defp build_solr_field({"245", [subfield]}, acc) do
    title = subfield
            |> get_subfields("abcfghknps")
            |> Enum.join(" ")
    acc
    |> Map.put(:title, title)
  end

  defp build_solr_field(_, acc) do
    acc
  end

  defp get_subfields(%MarcParser.DataField{subfields: subfields}, fields) do
    fields
    |> String.graphemes()
    |> Enum.map(&get_subfield_value(subfields[&1]))
    |> Enum.filter(fn x -> x != nil end)
  end

  defp get_subfield_value([%MarcParser.SubField{value: value}]) do
    value
  end

  defp get_subfield_value(_) do
    nil
  end
end
