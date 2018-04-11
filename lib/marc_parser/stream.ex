defmodule MarcParser.Stream do
  def from_handle(file_handle) do
    Stream.unfold(file_handle, &next_record_from_handle/1)
  end

  def next_record_from_handle(file_handle) do
    record_length = record_length(file_handle)
    if record_length > 0 do
      { extract_record(file_handle, record_length), file_handle }
    else
      nil
    end
  end

  def extract_record(marc_handle, record_length) do
    record_length_s = String.pad_leading(Integer.to_string(record_length), 5, ["0"])
    record = marc_handle
    |> IO.binread(record_length-5)
    record_length_s <> record
  end

  def record_length(file_handle) do
    record_length = IO.binread(file_handle, 5)
    case record_length do
      :eof -> 0
      _ -> String.to_integer(record_length)
    end
  end

end
