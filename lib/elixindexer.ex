defmodule Elixindexer do
  import SweetXml
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
    content
    |> xpath(
      ~x"//record"l,
      id: ~x"./controlfield[@tag='001']/text()"s,
      title: ~x"./datafield[@tag='245']/subfield/text()"sl |> transform_by(&Enum.join(&1, " "))
    )
  end
end
