defmodule DocPipeline.Repo.Migrations.CreateDocumentFields do
  use Ecto.Migration

  def change do
    create table(:document_fields, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :document_id,
          references(:documents,
            type: :binary_id,
            on_delete: :delete_all
          ),
          null: false

      add :field_name, :string, null: false
      add :field_value, :text
      add :confidence, :float
      add :source, :string, default: "system", null: false

      timestamps()
    end

    create index(:document_fields, [:document_id])
    create index(:document_fields, [:field_name])
  end
end
