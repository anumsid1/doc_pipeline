# lib/doc_pipeline/documents/document_line_item.ex
defmodule DocPipeline.Documents.DocumentLineItem do
  @moduledoc """
  A single line item extracted from a document (e.g. an invoice or
  budget line), sourced either from the AI extractor or added/edited
  by a user correction.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "document_line_items" do
    field :description, :string
    field :amount, :decimal
    field :category, :string
    field :line_number, :integer
    field :source, :string, default: "system"

    belongs_to :document, DocPipeline.Documents.Document

    timestamps()
  end

  def changeset(line_item, attrs) do
    line_item
    |> cast(attrs, [:description, :amount, :category, :line_number, :source, :document_id])
    |> validate_required([:description, :document_id])
    |> validate_inclusion(:source, ~w(system user))
    |> foreign_key_constraint(:document_id)
  end
end
