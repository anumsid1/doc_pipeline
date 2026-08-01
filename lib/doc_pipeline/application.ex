defmodule DocPipeline.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DocPipelineWeb.Telemetry,
      DocPipeline.Repo,
      {DNSCluster, query: Application.get_env(:doc_pipeline, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DocPipeline.PubSub},
      # Start a worker by calling: DocPipeline.Worker.start_link(arg)
      # {DocPipeline.Worker, arg},
      # Start to serve requests, typically the last entry
      DocPipelineWeb.Endpoint,
      {Oban, Application.fetch_env!(:doc_pipeline, Oban)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DocPipeline.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DocPipelineWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
