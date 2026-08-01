defmodule DocPipeline.Projects do
  @moduledoc """
  Context for creating and listing construction loan projects.
  """

  import Ecto.Query
  alias DocPipeline.Repo
  alias DocPipeline.Projects.Project

  def list_project() do
    Project
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def get_project(id) do
    case Repo.get(Project, id) do
      nil -> {:error, :not_found}
      project -> {:ok, project}
    end
  end

  def create_project(attrs) do
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end
end
