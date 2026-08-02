defmodule DocPipelineWeb.ProjectLive.Show do
  @moduledoc """
  A project's document workspace: upload new documents and see the
  status of documents already submitted against this project.
  """

  use DocPipelineWeb, :live_view

  alias DocPipeline.{Documents, Projects}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Projects.get_project(id) do
      {:ok, project} ->
        documents = Documents.list_documents_for_project(project.id)

        if connected?(socket) do
          Enum.each(documents, &subscribe/1)
        end

        {:ok,
         socket
         |> assign(:project, project)
         |> assign(:documents, documents)
         |> allow_upload(:document,
           accept: ~w(.pdf .xlsx .xls),
           max_entries: 1,
           max_file_size: 20_000_000
         )}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Project not found")
         |> push_navigate(to: ~p"/projects")}
    end
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :document, ref)}
  end

  def handle_event("upload", _params, socket) do
    uploaded =
      consume_uploaded_entries(socket, :document, fn %{path: path}, entry ->
        result =
          Documents.upload_document(
            socket.assigns.project.id,
            entry.client_name,
            entry.client_type,
            File.read!(path)
          )

        {:ok, result}
      end)

    case uploaded do
      [{:ok, document}] ->
        subscribe(document)

        {:noreply,
         socket
         |> update(:documents, &[document | &1])
         |> put_flash(:info, "#{document.filename} uploaded — processing started")}

      [{:error, _changeset}] ->
        {:noreply, put_flash(socket, :error, "Upload failed — please try again")}

      [] ->
        {:noreply, put_flash(socket, :error, "Choose a file first")}
    end
  end

  def handle_event("refresh", _params, socket) do
    documents = Documents.list_documents_for_project(socket.assigns.project.id)
    {:noreply, assign(socket, :documents, documents)}
  end

  @impl true
  def handle_info({:document_updated, document_id}, socket) do
    {:noreply, update(socket, :documents, &replace_document(&1, document_id))}
  end

  defp replace_document(documents, document_id) do
    case Documents.get_document(document_id) do
      {:ok, updated} -> Enum.map(documents, &if(&1.id == updated.id, do: updated, else: &1))
      {:error, :not_found} -> documents
    end
  end

  defp subscribe(document), do: Phoenix.PubSub.subscribe(DocPipeline.PubSub, "document:#{document.id}")

  defp status_badge_class("processed"), do: "badge-success"
  defp status_badge_class("processing"), do: "badge-info"
  defp status_badge_class("failed"), do: "badge-error"
  defp status_badge_class("requires_review"), do: "badge-warning"
  defp status_badge_class(_uploaded), do: "badge-neutral"

  defp upload_error_to_string(:too_large), do: "File is too large"
  defp upload_error_to_string(:not_accepted), do: "Unacceptable file type"
  defp upload_error_to_string(:too_many_files), do: "Only one file at a time"
end
