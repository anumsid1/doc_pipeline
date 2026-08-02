defmodule DocPipelineWeb.ProjectLive.Index do
  @moduledoc """
  Lists all projects, linking into each project's document workspace.
  """

  use DocPipelineWeb, :live_view

  alias DocPipeline.Projects

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :projects, Projects.list_project())}
  end
end
