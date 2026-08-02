defmodule DocPipelineWeb.DocumentLive.Show do
  @moduledoc """
  A single document's detail view: its extracted fields (inline
  editable) and line items, plus a control for correcting its
  classified domain type.
  """

  use DocPipelineWeb, :live_view

  alias DocPipeline.Documents
  alias DocPipeline.Documents.Document

  @impl true
  def mount(%{"project_id" => project_id, "id" => id}, _session, socket) do
    case Documents.get_document(id) do
      {:ok, document} ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(DocPipeline.PubSub, "document:#{document.id}")
        end

        {:ok,
         socket
         |> assign(:project_id, project_id)
         |> assign(:document, document)
         |> assign(:editing_field_id, nil)}

      {:error, :not_found} ->
        {:ok,
         socket
         |> put_flash(:error, "Document not found")
         |> push_navigate(to: ~p"/projects/#{project_id}")}
    end
  end

  @impl true
  def handle_event("edit_field", %{"id" => field_id}, socket) do
    {:noreply, assign(socket, :editing_field_id, field_id)}
  end

  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, :editing_field_id, nil)}
  end

  def handle_event("save_field", %{"field_id" => field_id, "value" => value}, socket) do
    case Documents.update_field(field_id, value) do
      {:ok, _field} ->
        {:noreply,
         socket
         |> assign(:document, reload!(socket))
         |> assign(:editing_field_id, nil)
         |> put_flash(:info, "Field updated")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not save field")}
    end
  end

  def handle_event("correct_type", %{"domain_type" => domain_type}, socket) do
    case Documents.correct_document_type(socket.assigns.document.id, domain_type) do
      {:ok, _document} ->
        {:noreply,
         socket
         |> assign(:document, reload!(socket))
         |> put_flash(:info, "Type corrected to #{domain_type} — re-extracting fields")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not correct type")}
    end
  end

  @impl true
  def handle_info({:document_updated, document_id}, socket) do
    if document_id == socket.assigns.document.id do
      {:noreply, assign(socket, :document, reload!(socket))}
    else
      {:noreply, socket}
    end
  end

  defp reload!(socket) do
    {:ok, document} = Documents.get_document(socket.assigns.document.id)
    document
  end

  defp status_badge_class("processed"), do: "badge-success"
  defp status_badge_class("processing"), do: "badge-info"
  defp status_badge_class("failed"), do: "badge-error"
  defp status_badge_class("requires_review"), do: "badge-warning"
  defp status_badge_class(_uploaded), do: "badge-neutral"

  defp humanize_type(type), do: type |> String.replace("_", " ") |> String.capitalize()
end
