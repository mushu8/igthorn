defmodule Hefty.Application do
  use Application

  @impl true
  def start(_type, _args) do
    workers = [
      {Hefty.Repo, []},
      {Hefty.Streaming.Binance.Supervisor, []},
      # Start the PubSub system
      {Phoenix.PubSub, name: Hefty.PubSub},
      # used for backtesting
      {Hefty.Streaming.Backtester.SimpleStreamer, []},
      {Hefty.Algos.Naive.Supervisor, []}
    ]

    backtesting_workers =
      case Application.fetch_env!(:hefty, :env) == "backtesting" do
        false -> []
        true -> [{Hefty.Exchanges.BinanceMock, []}]
      end

    Supervisor.start_link(
      workers ++ backtesting_workers,
      strategy: :one_for_one,
      name: Hefty.Supervisor
    )
  end
end
