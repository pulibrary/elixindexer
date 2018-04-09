 defmodule RecordParsingBench do
   use Benchfella
   setup_all do
     {:ok, 0}
   end

   bench "parse large file" do
     Elixindexer.parse_records("1520931620.xml")
   end
 end
