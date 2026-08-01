defmodule DocPipeline.Repo.Migrations.CreateDocumentLineItems do
  use Ecto.Migration

  def change do
    create table(:document_line_items, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :document_id,
          references(:documents,
            type: :binary_id,
            on_delete: :delete_all
          ),
          null: false

      add :description, :string
      add :amount, :decimal, precision: 12, scale: 2
      add :category, :string
      add :line_number, :integer
      add :source, :string, default: "system", null: false

      timestamps()
    end

    create index(:document_line_items, [:document_id])
  end
end
