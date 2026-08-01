defmodule DocPipeline.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:documents, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :project_id,
          references(:projects,
            type: :binary_id,
            on_delete: :delete_all
          ),
          null: false

      add :filename, :string, null: false
      add :content_type, :string, null: false
      add :storage_path, :string, null: false
      add :file_size, :integer
      add :domain_type, :string
      add :domain_type_source, :string, default: "system"
      add :status, :string, default: "uploaded", null: false
      add :raw_text, :text
      add :page_count, :integer
      add :error_message, :text
      add :processing_started_at, :utc_datetime
      add :processing_completed_at, :utc_datetime

      timestamps()
    end

    create index(:documents, [:project_id])
    create index(:documents, [:status])
    create index(:documents, [:domain_type])
  end
end
