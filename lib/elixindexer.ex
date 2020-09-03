defmodule Elixindexer do
  def parse_records(file_name) do
    {:ok, handle} = File.open(file_name, read_ahead: 512 * 1024)
    output = MarcParser.parse_marc(handle)
    |> Flow.partition(window: Flow.Window.count(5000))
    |> Flow.map(&solrize/1)
  end

  def index_records(flow) do
    flow
    |> Flow.reduce(fn -> [] end, fn item, list -> [ item | list] end)
    |> Flow.emit(:state)
    |> Flow.map(&index/1)
    {:ok, _} = solr_commit
  end

  defp index(records) do
    case output = solr_post(records) do
      {:ok, _} -> IO.puts("Indexed #{length(records)} records")
      {:error, _} -> IO.inspect(output)
    end
    records
  end

  defp solr_post(records) do
    HTTPoison.post(solr_url, :jiffy.encode(records), [{"Content-type", "application/json"}], solr_opts)
  end

  defp solr_commit do
    HTTPoison.get("#{solr_url}?commit=true", [], solr_opts)
  end

  defp solr_url do
    "http://elixindexer.test.solr.lndo.site/solr/blacklight-core-test/update"
  end

  defp solr_opts do
    [timeout: 60_000, recv_timeout: 60_000, hackney: [pool: :solr_pool]]
  end

  defp solrize(record = %MarcParser.Record{fields: fields}) do
    %{}
    |> get_id(record)
    |> get_title(record)
    |> get_author_display(record)
    |> get_author_s(record)
    |> get_subject_display(record)
  end

  defp get_id(solr_doc, record) do
    # id = hd(record.fields["001"]).value
    id =
      record
      |> extract_field("001")
      |> hd

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
      extract_field(record, "100", "aqbcdk") ++
        extract_field(record, "110", "abcdfgkln") ++ extract_field(record, "111", "abcdfgklnpq")

    solr_doc
    |> Map.put(:author_display, author)
  end

  defp get_author_s(solr_doc, record) do
    author =
      (extract_field(record, "100", "aqbcdk") ++
         extract_field(record, "110", "abcdfgkln") ++
         extract_field(record, "111", "abcdfgklnpq") ++
         extract_field(record, "700", "aqbcdk") ++
         extract_field(record, "710", "abcdfgkln") ++ extract_field(record, "711", "abcdfgklnpq"))
      |> Enum.map(&trim_punctuation/1)

    solr_doc
    |> Map.put(:author_s, author)
  end

  defp get_subject_display(solr_doc, record) do
    subjects =
      extract_field(record, "600", "abcdfklmnopqrtvxyz", indicator2: "0")
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
    |> Enum.map(&field_value/1)
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
      |> Enum.filter(fn field -> field.indicator2 == indicator2 end)
      |> extract_field(subfields)
  end

  # Extract values from fields with given subfield codes.
  defp extract_field(fields, subfields) when is_list(fields) do
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
