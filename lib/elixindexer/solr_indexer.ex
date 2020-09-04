defmodule Elixindexer.SolrIndexer do
  def index_records(flow) do
    flow
    |> Flow.reduce(fn -> [] end, fn item, list -> [item | list] end)
    |> Flow.emit(:state)
    |> Flow.partition(max_demand: 20, stages: 2)
    |> Flow.map(&index/1)
    |> Enum.to_list()

    {:ok, _} = solr_commit()
  end

  defp index(records) do
    case output = solr_post(records) do
      {:ok, _} -> IO.puts("Indexed #{length(records)} records")
      {:error, _} -> IO.inspect(output)
    end

    records
  end

  defp solr_post(records) do
    HTTPoison.post(
      solr_url(),
      :jiffy.encode(records),
      [{"Content-type", "application/json"}],
      solr_opts()
    )
  end

  defp solr_commit do
    HTTPoison.get("#{solr_url()}?commit=true", [], solr_opts())
  end

  defp solr_url do
    "http://elixindexer.test.solr.lndo.site/solr/blacklight-core-test/update"
  end

  defp solr_opts do
    [timeout: 60_000, recv_timeout: 60_000, hackney: [pool: :solr_pool]]
  end
end
