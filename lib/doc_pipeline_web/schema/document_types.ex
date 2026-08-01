# lib/doc_pipeline_web/schema/document_types.ex
defmodule DocPipelineWeb.Schema.DocumentTypes do
  @moduledoc """
  GraphQL object types, queries, and mutations for documents, their
  extracted fields, and their line items.
  """

  use Absinthe.Schema.Notation

  alias DocPipeline.Documents

  object :document do
    field :id, :id
    field :filename, :string
    field :content_type, :string
    field :domain_type, :string
    field :domain_type_source, :string
    field :status, :string
    field :file_size, :integer
    field :error_message, :string
    field :inserted_at, :string

    field :fields, list_of(:document_field)
    field :line_items, list_of(:document_line_item)
  end

  object :document_field do
    field :id, :id
    field :field_name, :string
    field :field_value, :string
    field :confidence, :float
    field :source, :string
  end

  object :document_line_item do
    field :id, :id
    field :description, :string
    field :amount, :float
    field :category, :string
    field :line_number, :integer
    field :source, :string
  end

  object :document_queries do
    field :documents, list_of(:document) do
      arg(:project_id, non_null(:id))
      arg(:domain_type, :string)

      resolve(fn _, %{project_id: pid} = args, _ ->
        docs =
          case args[:domain_type] do
            nil -> Documents.list_documents_for_project(pid)
            type -> Documents.get_document_by_type(pid, type)
          end

        {:ok, docs}
      end)
    end

    field :document, :document do
      arg(:id, non_null(:id))

      resolve(fn _, %{id: id}, _ ->
        Documents.get_document(id)
      end)
    end
  end

  object :document_mutations do
    field :upload_document, :document do
      arg(:project_id, non_null(:id))
      arg(:filename, non_null(:string))
      arg(:content_type, non_null(:string))
      # In production: file upload via multipart
      # For now: accepts base64 encoded content
      arg(:content_base64, non_null(:string))

      resolve(fn _, args, _ ->
        binary = Base.decode64!(args.content_base64)

        Documents.upload_document(
          args.project_id,
          args.filename,
          args.content_type,
          binary
        )
      end)
    end

    field :correct_document_type, :document do
      arg(:document_id, non_null(:id))
      arg(:domain_type, non_null(:string))

      resolve(fn _, args, _ ->
        Documents.correct_document_type(args.document_id, args.domain_type)
      end)
    end

    field :update_document_field, :document_field do
      arg(:field_id, non_null(:id))
      arg(:field_value, non_null(:string))

      resolve(fn _, %{field_id: id, field_value: value}, _ ->
        Documents.update_field(id, value)
      end)
    end
  end
end
