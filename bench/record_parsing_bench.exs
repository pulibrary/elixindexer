 defmodule RecordParsingBench do
   use Benchfella

   bench "parse large file" do
     Elixindexer.parse_records("small_set.mrc")
   end
 end
