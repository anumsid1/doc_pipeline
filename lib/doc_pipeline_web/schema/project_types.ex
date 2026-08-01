# lib/doc_pipeline_web/schema/project_types.ex
defmodule DocPipelineWeb.Schema.ProjectTypes do
  @moduledoc """
  GraphQL object type, queries, and mutations for projects.
  """

  use Absinthe.Schema.Notation

  alias DocPipeline.Projects

  object :project do
    field :id, :id
    field :name, :string
    field :address, :string
    field :total_budget, :float
    field :status, :string
    field :inserted_at, :string

    field :documents, list_of(:document) do
      resolve(fn project, _, _ ->
        docs = DocPipeline.Documents.list_documents_for_project(project.id)
        {:ok, docs}
      end)
    end
  end

  object :project_queries do
    field :projects, list_of(:project) do
      resolve(fn _, _, _ ->
        {:ok, Projects.list_project()}
      end)
    end

    field :project, :project do
      arg(:id, non_null(:id))

      resolve(fn _, %{id: id}, _ ->
        Projects.get_project(id)
      end)
    end
  end

  object :project_mutations do
    field :create_project, :project do
      arg(:name, non_null(:string))
      arg(:address, :string)
      arg(:total_budget, :float)

      resolve(fn _, args, _ ->
        Projects.create_project(args)
      end)
    end
  end
end
