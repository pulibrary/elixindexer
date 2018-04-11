 defmodule RecordParsingBench do
   use Benchfella

   bench "parse large file" do
     Elixindexer.parse_records("20.mrc")
   end
 end
