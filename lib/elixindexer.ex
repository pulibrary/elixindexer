defmodule Elixindexer do
  import MarcParser.Helper
  def parse_records(file_name) do
    {:ok, handle} = File.open(file_name, read_ahead: 512 * 1024)
    output = MarcParser.parse_marc(handle)
    |> Flow.partition(window: Flow.Window.count(500))
    |> Flow.map(&solrize/1)
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

end
