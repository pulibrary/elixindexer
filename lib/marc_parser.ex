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
  @subfield_indicator 0x1F
  def parse_marc(marc_handle) do
    MarcParser.Stream.from_handle(marc_handle)
    |> Flow.from_enumerable
    |> Flow.map(&parse_record/1)
  end

  def parse_record(marc_record) do
    leader = marc_record |> Kernel.binary_part(0, @leader_length)
    base_address = leader |> Kernel.binary_part(12, 5) |> String.to_integer
    directory = marc_record |> Kernel.binary_part(@leader_length, base_address-@leader_length-1)
    num_fields = div(byte_size(directory), @directory_entry_length)
    fields = Enum.reduce(0..(num_fields-1), %{}, &extract_field(marc_record, directory, base_address, &1, &2))
    %MarcParser.Record{leader: leader, fields: fields}
  end

  def extract_field(marc_record, directory, base_address, field_num, acc) do
    entry_start = field_num * @directory_entry_length
    entry_end = entry_start + @directory_entry_length
    entry = Kernel.binary_part(directory, entry_start, entry_end-entry_start)
    tag = Kernel.binary_part(entry, 0, 3)
    field_length = Kernel.binary_part(entry, 3, 4) |> String.to_integer
    field_offset = Kernel.binary_part(entry, 7, 5) |> String.to_integer
    field_start = base_address + field_offset
    field_data = Kernel.binary_part(marc_record, field_start, field_length) |> remove_field_end
    field = generate_field(tag, field_data)
    case Map.fetch(acc, tag) do
      :error        -> acc |> Map.put(tag, [field])
      {:ok, value}  -> acc |> Map.put(tag, value ++ [field])
      _             -> acc
    end
  end

  def generate_field(tag = "001", field_data) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag = "002", field_data) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag = "003", field_data) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag = "004", field_data) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag = "005", field_data) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag = "006", field_data) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag = "007", field_data) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag = "008", field_data) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag = "009", field_data) do
    generate_control_field(tag, field_data)
  end
  def generate_field(tag, field_data) do
    generate_data_field(tag, field_data)
  end

  def generate_control_field(tag, field_data) do
    %MarcParser.ControlField{tag: tag, value: field_data}
  end

  def generate_data_field(tag, field_data) do
    [indicators | subfields] = field_data |> :binary.split([<<@subfield_indicator>>], [:global])
    [indicator1, indicator2] = indicators |> String.codepoints
    subfields = subfields
                |> Enum.reduce(%{}, &generate_subfield/2)
    %MarcParser.DataField{tag: tag, indicator1: indicator1, indicator2: indicator2, subfields: subfields}
  end

  def generate_subfield(subfield_data, acc) do
    if byte_size(subfield_data) == 0 do
      acc
    else
      tag = binary_part(subfield_data, 0, 1)
      value = binary_part(subfield_data, 1, byte_size(subfield_data)-1)
      field = %MarcParser.SubField{code: tag, value: value}
      case Map.fetch(acc, tag) do
        :error        -> acc |> Map.put(tag, [field])
        {:ok, value}  -> acc |> Map.put(tag, value ++ [field])
        _             -> acc
      end
    end
  end

  def remove_field_end(field_data) do
    case :binary.last(field_data) do
      0x1E -> binary_part(field_data, 0, byte_size(field_data) - 1)
      _ -> field_data
    end
  end


end
