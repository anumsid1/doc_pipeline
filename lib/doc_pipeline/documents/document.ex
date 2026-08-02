# lib/doc_pipeline/documents/document.ex
defmodule DocPipeline.Documents.Document do
  @moduledoc """
  An uploaded file belonging to a project, along with the metadata
  tracking its classification and processing pipeline status. Owns
  the fields and line items extracted from it.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_types ~w(invoice budget change_order pay_application)
  @valid_statuses ~w(uploaded processing processed failed requires_review)
  @valid_sources ~w(system user)

  def valid_types, do: @valid_types

  schema "documents" do
    field :filename, :string
    field :content_type, :string
    field :storage_path, :string
    field :file_size, :integer
    field :domain_type, :string
    field :domain_type_source, :string, default: "system"
    field :status, :string, default: "uploaded"
    field :raw_text, :string
    field :page_count, :integer
    field :error_message, :string
    field :processing_started_at, :utc_datetime
    field :processing_completed_at, :utc_datetime

    belongs_to :project, DocPipeline.Projects.Project
    has_many :fields, DocPipeline.Documents.DocumentField
    has_many :line_items, DocPipeline.Documents.DocumentLineItem

    timestamps()
  end

  def changeset(document, attrs) do
    document
    |> cast(attrs, [
      :filename,
      :content_type,
      :storage_path,
      :file_size,
      :domain_type,
      :domain_type_source,
      :status,
      :raw_text,
      :page_count,
      :error_message,
      :project_id,
      :processing_started_at,
      :processing_completed_at
    ])
    |> validate_required([:filename, :content_type, :storage_path, :project_id])
    |> validate_inclusion(:domain_type, @valid_types)
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_inclusion(:domain_type_source, @valid_sources)
    |> foreign_key_constraint(:project_id)
  end
end
