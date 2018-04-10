require IEx
defmodule Elixindexer do
  def parse_records(file_name) do
    {:ok, handle} = File.open(file_name)
    result = MarcParser.parse_marc(handle)
  end
end
