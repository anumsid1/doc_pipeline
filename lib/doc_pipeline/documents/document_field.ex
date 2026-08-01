# lib/doc_pipeline/documents/document_field.ex
defmodule DocPipeline.Documents.DocumentField do
  @moduledoc """
  A single extracted key/value field belonging to a document (e.g.
  vendor_name, invoice_number), sourced either from the AI extractor
  or overridden by a user correction.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "document_fields" do
    field :field_name, :string
    field :field_value, :string
    field :confidence, :float
    field :source, :string, default: "system"

    belongs_to :document, DocPipeline.Documents.Document

    timestamps()
  end

  def changeset(field, attrs) do
    field
    |> cast(attrs, [:field_name, :field_value, :confidence, :source, :document_id])
    |> validate_required([:field_name, :document_id])
    |> validate_inclusion(:source, ~w(system user))
    |> validate_number(:confidence,
      greater_than_or_equal_to: 0.0,
      less_than_or_equal_to: 1.0
    )
    |> foreign_key_constraint(:document_id)
  end
end
