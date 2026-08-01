defmodule DocPipeline.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :address, :string
      add :total_budget, :decimal, precision: 12, scale: 2
      add :status, :string, default: "active"

      timestamps()
    end
  end
end
