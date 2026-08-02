# lib/doc_pipeline/workers/process_document_worker.ex
defmodule DocPipeline.Workers.ProcessDocumentWorker do
  @moduledoc """
  Background job that runs a document through the full processing
  pipeline: extract raw text, classify domain type (unless already
  specified), extract structured fields/line items, and persist the
  results, updating the document's status along the way.
  """

  use Oban.Worker,
    queue: :document_processing,
    max_attempts: 3,
    unique: [period: 300, fields: [:worker, :args]]

  alias DocPipeline.Documents
  require Logger

  @impl true
  def perform(%Oban.Job{args: args}) do
    document_id = args["document_id"]
    skip_classification = args["skip_classification"] || false

    with {:ok, document} <- Documents.get_document(document_id),
         {:ok, document} <- Documents.update_document_status(document, "processing"),
         {:ok, raw_text} <- extract_text(document),
         {:ok, document} <- Documents.save_raw_text(document, raw_text),
         {:ok, domain_type} <- maybe_classify(document, raw_text, skip_classification),
         {:ok, document} <- Documents.update_document_type(document, domain_type),
         {:ok, extracted} <- extract_data(domain_type, raw_text),
         {:ok, _} <- save_extracted(document, extracted) do
      Documents.update_document_status(document, "processed")
      broadcast_update(document_id)

      :ok
    else
      {:error, reason} ->
        Logger.error("Document processing failed: #{inspect(reason)}")

        with {:ok, doc} <- Documents.get_document(document_id) do
          Documents.update_document_status(doc, "failed", inspect(reason))
        end

        broadcast_update(document_id)

        {:error, reason}
    end
  end

  defp broadcast_update(document_id) do
    Phoenix.PubSub.broadcast(
      DocPipeline.PubSub,
      "document:#{document_id}",
      {:document_updated, document_id}
    )
  end

  defp extract_text(%{content_type: "application/pdf"} = doc) do
    # For now, read the file and simulate text extraction
    case File.read(doc.storage_path) do
      {:ok, _binary} ->
        # In production: use PDF text extraction library
        # For now: treat the binary as text or return placeholder
        {:ok, "Simulated PDF text for #{doc.filename}"}

      {:error, reason} ->
        {:error, {:file_read_failed, reason}}
    end
  end

  defp extract_text(%{content_type: ct} = doc)
       when ct in [
              "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              "application/vnd.ms-excel"
            ] do
    case File.read(doc.storage_path) do
      {:ok, _binary} ->
        # In production: parse Excel with Xlsxir
        {:ok, "Simulated Excel content for #{doc.filename}"}

      {:error, reason} ->
        {:error, {:file_read_failed, reason}}
    end
  end

  defp extract_text(_doc), do: {:error, :unsupported_content_type}

  defp maybe_classify(document, _raw_text, true) do
    # Skip classification — user already specified the type
    {:ok, document.domain_type}
  end

  defp maybe_classify(_document, raw_text, false) do
    classifier().classify(raw_text)
  end

  defp extract_data(domain_type, raw_text) do
    extractor().extract(domain_type, raw_text)
  end

  defp save_extracted(document, %{"fields" => fields, "line_items" => items}) do
    Documents.save_extracted_fields(document, fields)
    Documents.save_line_items(document, items)
    {:ok, document}
  end

  defp save_extracted(document, %{"fields" => fields}) do
    Documents.save_extracted_fields(document, fields)
    {:ok, document}
  end

  defp classifier do
    Application.get_env(:doc_pipeline, :classifier, DocPipeline.AI.Classifier)
  end

  defp extractor do
    Application.get_env(:doc_pipeline, :extractor, DocPipeline.AI.Extractor)
  end
end
