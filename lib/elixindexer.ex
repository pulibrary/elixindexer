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

  def parse_record(_) do
    nil
  end

  def build_record(fields) do
    fields
    |> Enum.reduce(%{}, &build_record/2)
  end

  def build_record({:xmlel, "controlfield", [{"tag", "001"}], [xmlcdata: id]}, acc = %{}) do
    acc
    |> Map.put(:id, id)
  end

  def build_record({:xmlel, "datafield", [{_, _}, {_, _}, {"tag", "245"}], fields}, acc = %{}) do
    title = fields
    |> Enum.map(&get_data/1)
    |> Enum.join(" ")
    acc
    |> Map.put(:title, title)
  end

  def build_record(_, acc = %{}) do
    acc
  end

  def get_data({:xmlel, _, _, [xmlcdata: data]}) do
    data
  end

  # {:xmlel, "datafield", [{"ind1", "1"}, {"ind2", "0"}, {"tag", "245"}],
end
