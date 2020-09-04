defmodule MarcParser.Helper do
  # Extract tag from a record.
  def extract_field(record = %MarcParser.Record{}, tag) do
    record.fields[tag]
    |> Enum.map(&field_value/1)
  end

  # Extract given subfield codes from a tag on a record.
  def extract_field(record, tag, subfields) do
    case fields = record.fields[tag] do
      nil -> []
      _ -> fields |> extract_field(subfields)
    end
  end

  # Extract given subfield codes from a tag on a record with given indicator.
  def extract_field(record, tag, subfields, indicator2: indicator2) do
    fields =
      (record.fields[tag] || [])
      |> Enum.filter(fn field -> field.indicator2 == indicator2 end)
      |> extract_field(subfields)
  end

  # Extract values from fields with given subfield codes.
  def extract_field(fields, subfields) when is_list(fields) do
    fields
    |> Enum.filter(fn x -> x.subfields != [] end)
    |> Enum.map(&field_value(&1, String.graphemes(subfields)))
  end

  defp field_value(%MarcParser.ControlField{value: value}) do
    value
  end

  defp field_value(%MarcParser.DataField{subfields: subfields}) do
    subfields
    |> subfield_join
  end

  defp field_value(%MarcParser.DataField{subfields: subfields}, subfield_codes) do
    subfields
    |> Enum.filter(fn x -> Enum.member?(subfield_codes, x.code) end)
    |> subfield_join
  end

  defp subfield_join([]) do
    ""
  end

  defp subfield_join([subfield1 = %{}]) do
    subfield1.value
  end

  defp subfield_join([subfield = %{} | [subfield2 = %{}]]) do
    subfield_join([subfield.value, subfield2])
  end

  defp subfield_join([subfield | [subfield2 = %{code: code}]])
       when is_binary(subfield) and code in ["v", "x", "y", "z"] do
    "#{subfield}—#{subfield2.value}"
  end

  defp subfield_join([subfield | [subfield2 = %{}]]) when is_binary(subfield) do
    "#{subfield} #{subfield2.value}"
  end

  defp subfield_join([subfield | [subfield2 | more_subfields]]) do
    subfield_join([subfield_join([subfield, subfield2]) | more_subfields])
  end
end
