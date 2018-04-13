defmodule Elixindexer do
  def parse_records(file_name) do
    {:ok, handle} = File.open(file_name, read_ahead: 512 * 1024)

    MarcParser.parse_marc(handle)
    |> Flow.partition()
    |> Flow.map(&solrize/1)
    |> Enum.sort()
  end

  defp solrize(record = %MarcParser.Record{leader: leader, fields: fields}) do
    %{}
    |> get_id(record)
    |> get_title(record)
    |> get_author_display(record)
    |> get_author_s(record)
    |> get_subject_display(record)
    |> get_format(record)
  end

# Audio
# Book
# Data file
# Journal
# Manuscript
# Map
# Musical score
# Senior thesis
# Video/Projected medium
# Visual material

# Book => ta abcdim
# Journal => a s
# Data File => m
# Audio => ij
# Visual Material => kor
# Video/Project medium => g
# Musical score => cd
# Map => ef
# Manuscript => dfpt
# Senior thesis (Marc 502 $b = Princeton University)

  defp get_format(solr_doc, record) do
    format =
      String.graphemes(record.leader)
      |> Enum.slice(6, 2)
      |> determine_format
    Map.put(solr_doc, :format, format)
  end

  defp determine_format(leader_67) do
    case position_6 = hd(leader_67) do
      "a" -> ["Journal"]
      "t" -> ["Book"]
      "m" -> ["Data file"]
      "i" -> ["Audio"]
      "j" -> ["Audio"]
      "k" -> ["Visual material"]
      "o" -> ["Visual material"]
      "r" -> ["Visual material"]
      "c" -> ["Musical score"]
      "d" -> ["Musical score"]
      "e" -> ["Map"]
      "f" -> ["Map", "Manuscript"]
      "d" -> ["Manuscript"]
      "p" -> ["Manuscript"]
      "t" -> ["Manuscript"]
      _ -> ["Unknown"]
    end
  end

  defp get_id(solr_doc, record) do
    id =
      record
      |> extract_field("001")
      |> Enum.at(0)

    solr_doc
    |> Map.put(:id, id)
  end

  defp get_title(solr_doc, record) do
    title =
      record
      |> extract_field("245", "abcfghknps")
      |> Enum.at(0)

    solr_doc
    |> Map.put(:title_display, title)
  end

  defp get_author_display(solr_doc, record) do
    author =
      extract_field(record, "100", "aqbcdk")
      |> Stream.concat(extract_field(record, "110", "abcdfgkln"))
      |> Stream.concat(extract_field(record, "111", "abcdfgklnpq"))
      |> Enum.to_list

    solr_doc
    |> Map.put(:author_display, author)
  end

  defp get_author_s(solr_doc, record) do
    author =
      extract_field(record, "100", "aqbcdk")
      |> Stream.concat(extract_field(record, "110", "abcdfgkln"))
      |> Stream.concat(extract_field(record, "111", "abcdfgklnpq"))
      |> Stream.concat(extract_field(record, "700", "aqbcdk"))
      |> Stream.concat(extract_field(record, "710", "abcdfgkln"))
      |> Stream.concat(extract_field(record, "711", "abcdfgklnpq"))
      |> Enum.map(&trim_punctuation/1)

    solr_doc
    |> Map.put(:author_s, author)
  end

  defp get_subject_display(solr_doc, record) do
    subjects =
      extract_field(record, "600", "abcdfklmnopqrtvxyz", indicator2: "0")
      |> Stream.concat(extract_field(record, "610", "abfklmnoprstvxyz"))
      |> Stream.concat(extract_field(record, "611", "abcdefgklnpqstvxyz"))
      |> Stream.concat(extract_field(record, "630", "adfgklmnoprstvxyz"))
      |> Stream.concat(extract_field(record, "650", "abcvxyz"))
      |> Stream.concat(extract_field(record, "651", "avxyz"))
      |> Enum.map(&trim_punctuation/1)

    solr_doc
    |> Map.put(:subject_display, subjects)
  end

  defp trim_punctuation(str) do
    str
    |> String.trim_trailing(".")
  end

  # Extract tag from a record.
  defp extract_field(record = %MarcParser.Record{}, tag) do
    record.fields[tag]
    |> Stream.map(&field_value/1)
  end

  # Extract given subfield codes from a tag on a record.
  defp extract_field(record, tag, subfields) do
    case fields = record.fields[tag] do
      nil -> []
      _ -> fields |> extract_field(subfields)
    end
  end

  # Extract given subfield codes from a tag on a record with given indicator.
  defp extract_field(record, tag, subfields, indicator2: indicator2) do
    fields =
      (record.fields[tag] || [])
      |> Stream.filter(fn field -> field.indicator2 == indicator2 end)
      |> extract_field(subfields)
  end

  # Extract values from fields with given subfield codes.
  defp extract_field(fields, subfields) when is_list(fields) do
    fields
    |> Stream.filter(fn x -> x.subfields != [] end)
    |> Stream.map(&field_value(&1, String.graphemes(subfields)))
  end

  defp extract_field(fields = %Stream{}, subfields) do
    fields
    |> Stream.filter(fn x -> x.subfields != [] end)
    |> Stream.map(&field_value(&1, String.graphemes(subfields)))
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
    |> Stream.filter(fn x -> Enum.member?(subfield_codes, x.code) end)
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

  defp subfield_join(stream) do
    subfield_join(stream |> Enum.to_list)
  end
end
