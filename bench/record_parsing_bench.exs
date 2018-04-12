 defmodule RecordParsingBench do
   use Benchfella

   # bench "parse large file" do
   #   Elixindexer.parse_records(["20.mrc"])
   # end
   bench "parse everything" do
     File.ls!("full_dump")
     |> Enum.map(fn (x) -> "full_dump/#{x}" end)
     |> Elixindexer.parse_records
   end
 end
