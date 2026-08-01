defmodule DocPipeline.Projects.Project do
  @moduledoc """
  A construction loan project. Owns the documents uploaded against it.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "projects" do
    field :name, :string
    field :address, :string
    field :total_budget, :decimal
    field :status, :string, default: "active"

    has_many :documents, DocPipeline.Documents.Document

    timestamps()
  end

  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :address, :total_budget, :status])
    |> validate_required([:name])
    |> validate_inclusion(:status, ~w(active completed archived))
  end
end
