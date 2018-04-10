defmodule Elixindexer do
  @moduledoc """
  Documentation for Elixindexer.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Elixindexer.hello
      :world

  """
  def hello do
    :world
  end

  def parse_records(file_name) do
    {:ok, content} = File.read(file_name)
    {:xmlel, "collection", _, records} = :fxml_stream.parse_element(content)
    records
    |> Enum.map(&parse_record/1)
    |> Enum.filter(fn(x) -> x != nil end)
  end

  def parse_record({:xmlel, "record", _, fields}) do
    build_record(fields)
  end

  # Skip any fields without record tag.
  def parse_record(_) do
    nil
  end

  def build_record(fields) do
    fields
    |> Enum.reduce(%{}, &build_record/2)
  end

  # Convert 001 to id
  def build_record({:xmlel, "controlfield", [{"tag", "001"}], [xmlcdata: id]}, acc = %{}) do
    acc
    |> Map.put(:id, id)
  end

  # Convert 245 to title.
  def build_record({:xmlel, "datafield", [{_, _}, {_, _}, {"tag", "245"}], fields}, acc = %{}) do
    title = fields
    |> Enum.map(&get_data(&1, ["a","b","c","f","g","h","k","n","p","s"]))
    |> Enum.filter(fn(x) -> x != nil end)
    |> Enum.join(" ")
    acc
    |> Map.put(:title, title)
  end

  def build_record(_, acc = %{}) do
    acc
  end

  def get_data({:xmlel, _, [{"code", code}], [xmlcdata: data]}, codes) do
    if Enum.member?(codes, code) do
      data
    else
      nil
    end
  end

  def get_data(_, _) do
    nil
  end
end
