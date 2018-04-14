defmodule Elixindexer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      :hackney_pool.child_spec(:solr_pool, [timeout: 60_000, max_connections: 100])
      # Starts a worker by calling: Elixindexer.Worker.start_link(arg)
      # {Elixindexer.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Elixindexer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
