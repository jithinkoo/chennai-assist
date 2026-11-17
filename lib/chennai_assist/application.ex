defmodule ChennaiAssist.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ChennaiAssistWeb.Telemetry,
      ChennaiAssist.Repo,
      # Production: create/update tables before serving requests, then load
      # starter articles and the admin account (both idempotent).
      {Ecto.Migrator,
       repos: Application.fetch_env!(:chennai_assist, :ecto_repos), skip: !auto_migrate?()},
      Supervisor.child_spec({Task, &seed/0}, id: :seed, restart: :temporary),
      {DNSCluster, query: Application.get_env(:chennai_assist, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ChennaiAssist.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ChennaiAssist.Finch},
      # Start a worker by calling: ChennaiAssist.Worker.start_link(arg)
      # {ChennaiAssist.Worker, arg},
      # Start to serve requests, typically the last entry
      ChennaiAssistWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ChennaiAssist.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp auto_migrate?, do: Application.get_env(:chennai_assist, :auto_migrate, false)

  defp seed do
    if auto_migrate?() do
      Code.eval_file(Path.join(:code.priv_dir(:chennai_assist), "repo/seeds.exs"))
    end

    :ok
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChennaiAssistWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
