defmodule DocPipeline.Documents do
  @moduledoc """
  Context for uploading documents and managing the results of their
  AI-driven classification and field/line-item extraction, including
  user corrections to those results.
  """

  import Ecto.Query
  alias DocPipeline.Repo
  alias DocPipeline.Documents.{Document, DocumentField, DocumentLineItem}

  def list_documents_for_project(project_id) do
    Document
    |> where([d], d.project_id == ^project_id)
    |> preload([:fields, :line_items])
    |> order_by(desc: :inserted_at)
    |> Repo.all()
  end

  def get_document(id) do
    Document
    |> preload([:fields, :line_items])
    |> Repo.get(id)
    |> case do
      nil -> {:error, :not_found}
      doc -> {:ok, doc}
    end
  end

  def get_document_by_type(project_id, domain_type) do
    Document
    |> where([d], d.project_id == ^project_id)
    |> where([d], d.domain_type == ^domain_type)
    |> preload([:fields, :line_items])
    |> Repo.all()
  end

  def upload_document(project_id, filename, content_type, file_binary) do
    storage_path = store_file(filename, file_binary)

    attrs = %{
      project_id: project_id,
      filename: filename,
      content_type: content_type,
      storage_path: storage_path,
      file_size: byte_size(file_binary),
      status: "uploaded"
    }

    with {:ok, document} <- create_document(attrs) do
      %{document_id: document.id}
      |> DocPipeline.Workers.ProcessDocumentWorker.new()
      |> Oban.insert()

      {:ok, document}
    end
  end

  defp create_document(attrs) do
    %Document{}
    |> Document.changeset(attrs)
    |> Repo.insert()
  end

  defp store_file(filename, binary) do
    dir = Path.join(["priv", "uploads"])
    File.mkdir_p!(dir)
    path = Path.join(dir, "#{Ecto.UUID.generate()}_#{filename}")
    File.write!(path, binary)
    path
  end

  def update_document_status(document, status, error \\ nil) do
    attrs = %{status: status, error_message: error}

    attrs =
      if status == "processing" do
        Map.put(attrs, :processing_started_at, DateTime.utc_now())
      else
        attrs
      end

    attrs =
      if status == "processed" do
        Map.put(attrs, :processing_completed_at, DateTime.utc_now())
      else
        attrs
      end

    document
    |> Document.changeset(attrs)
    |> Repo.update()
  end

  def update_document_type(document, domain_type, source \\ "system") do
    document
    |> Document.changeset(%{
      domain_type: domain_type,
      domain_type_source: source
    })
    |> Repo.update()
  end

  def save_raw_text(document, text) do
    document
    |> Document.changeset(%{raw_text: text})
    |> Repo.update()
  end

  def save_extracted_fields(document, fields_map) do
    Enum.each(fields_map, fn {name, value} ->
      %DocumentField{}
      |> DocumentField.changeset(%{
        document_id: document.id,
        field_name: to_string(name),
        field_value: to_string(value),
        confidence: 0.85,
        source: "system"
      })
      |> Repo.insert!()
    end)

    {:ok, document}
  end

  def save_line_items(document, items) do
    items
    |> Enum.with_index(1)
    |> Enum.each(fn {item, index} ->
      %DocumentLineItem{}
      |> DocumentLineItem.changeset(%{
        document_id: document.id,
        description: item["description"],
        amount: item["amount"],
        category: item["category"],
        line_number: index,
        source: "system"
      })
      |> Repo.insert!()
    end)

    {:ok, document}
  end

  # ── User corrections ───────────────────────────────

  def update_field(field_id, new_value) do
    case Repo.get(DocumentField, field_id) do
      nil ->
        {:error, :not_found}

      field ->
        field
        |> DocumentField.changeset(%{
          field_value: new_value,
          source: "user",
          confidence: 1.0
        })
        |> Repo.update()
    end
  end

  def correct_document_type(document_id, new_type) do
    with {:ok, document} <- get_document(document_id) do
      Repo.delete_all(from f in DocumentField, where: f.document_id == ^document_id)
      Repo.delete_all(from li in DocumentLineItem, where: li.document_id == ^document_id)

      # Update type
      {:ok, updated} = update_document_type(document, new_type, "user")

      # Re-enqueue extraction with correct type
      %{document_id: document_id, skip_classification: true}
      |> DocPipeline.Workers.ProcessDocumentWorker.new()
      |> Oban.insert()

      {:ok, updated}
    end
  end
end
