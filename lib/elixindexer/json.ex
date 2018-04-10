defmodule Elixindexer.Json do
  @moduledoc """
  Documentation for Elixindexer.
  """
  def parse_records(file_name) do
    {:ok, content} = File.read(file_name)
    Jason.decode!(content)
    |> Enum.map(&parse_record/1)
    |> Enum.filter(fn(x) -> x != nil end)
  end

  def parse_record(json) do
    build_record(json["fields"])
  end

  def build_record(fields) do
    fields
    |> Enum.reduce(%{}, &build_record/2)
  end

  def build_record(%{"001" => id}, acc) do
    acc
    |> Map.put(:id, id)
  end

  def build_record(%{"245" => fields}, acc) do
    title = fields["subfields"]
    |> Enum.map(&get_subfield_value(&1, ["a","b","c","f","g","h","k","n","p","s"]))
    |> Enum.filter(fn(x) -> x != nil end)
    |> Enum.join(" ")

    acc
    |> Map.put(:title, title)
  end

  def build_record(_, acc) do
    acc
  end

  def get_subfield_value(subfield, codes) do
    code = hd(Map.keys(subfield))
    if Enum.member?(codes, code) do
      subfield[code]
    else
      nil
    end
  end
end
