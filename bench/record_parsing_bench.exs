 defmodule RecordParsingBench do
   use Benchfella

   bench "parse large file" do
     Elixindexer.Json.parse_records("marc.json")
   end
 end
