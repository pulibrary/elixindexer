defmodule MarcParser do
  defmodule ControlField do
    defstruct tag: nil, value: nil
  end
  defmodule DataField do
    defstruct tag: nil, indicator1: nil, indicator2: nil, subfields: []
  end
  defmodule SubField do
    defstruct code: nil, value: nil
  end
  defmodule Record do
    defstruct fields: [], leader: nil
  end
  @leader_length 24
  @directory_entry_length 12
  def parse_marc(marc_handle) do
    MarcParser.Stream.from_handle(marc_handle)
    |> Flow.from_enumerable
    |> Flow.map(&parse_record/1)
  end

  def parse_record(marc_record) do
    <<leader::binary-size(@leader_length), _::binary>> = marc_record
    <<_::binary-size(12), base_address::binary-size(5), _::binary>> = leader
    base_address = base_address |> :erlang.binary_to_integer
    width = base_address-@leader_length-1
    <<_::binary-size(@leader_length), directory::binary-size(width), _::binary>> = marc_record
    num_fields = div(byte_size(directory), @directory_entry_length)
    subfield_pattern = :binary.compile_pattern(<<0x1F>>)
    fields = Enum.reduce(0..(num_fields-1), %{}, &extract_field(marc_record, directory, base_address, subfield_pattern, &1, &2))
    %MarcParser.Record{leader: leader, fields: fields}
  end

  def extract_field(marc_record, directory, base_address, subfield_pattern, field_num, acc) do
    entry_start = field_num * @directory_entry_length
    <<_::binary-size(entry_start), tag::binary-size(3), field_length::binary-size(4), field_offset::binary-size(5), _::binary>> = directory
    # entry = Kernel.binary_part(directory, entry_start, entry_width)
    field_length = field_length |> :erlang.binary_to_integer
    field_length = field_length - 1
    field_offset = field_offset |> :erlang.binary_to_integer
    field_start = base_address + field_offset
    <<_::binary-size(field_start), field_data::binary-size(field_length), _::binary>> = marc_record
    field = generate_field(tag, field_data, subfield_pattern)
    case Map.fetch(acc, tag) do
      :error        -> acc |> Map.put(tag, [field])
      {:ok, value}  -> acc |> Map.put(tag, value ++ [field])
      _             -> acc
    end
  end

  def generate_field(tag = "001", field_data, _) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag = "002", field_data, _) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag = "003", field_data, _) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag = "004", field_data, _) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag = "005", field_data, _) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag = "006", field_data, _) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag = "007", field_data, _) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag = "008", field_data, _) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag = "009", field_data, _) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag, field_data, subfield_pattern) do
    generate_data_field(tag, field_data, subfield_pattern)
  end

  def generate_control_field(tag, field_data) do
    %MarcParser.ControlField{tag: tag, value: field_data}
  end

  def generate_data_field(tag, field_data, subfield_pattern) do
    [indicators | subfields] = field_data |> :binary.split(subfield_pattern, [:global])
    <<indicator1::binary-size(1), indicator2::binary-size(1)>> = indicators
    subfields = subfields
                |> Enum.reduce([], &generate_subfield/2)
    %MarcParser.DataField{tag: tag, indicator1: indicator1, indicator2: indicator2, subfields: subfields}
  end

  def generate_subfield(subfield_data, acc) do
    if byte_size(subfield_data) == 0 do
      acc
    else
      <<code::binary-size(1), value::binary>> = subfield_data
      field = %MarcParser.SubField{code: code, value: value}
      acc ++ [field]
    end
  end

end
