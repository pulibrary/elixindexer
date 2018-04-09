 defmodule RecordParsingBench do
   use Benchfella

   bench "parse large file" do
     Elixindexer.parse_records("1520931620.xml")
   end
 end
