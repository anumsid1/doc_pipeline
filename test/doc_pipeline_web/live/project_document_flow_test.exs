defmodule DocPipelineWeb.ProjectDocumentFlowTest do
  use DocPipelineWeb.ConnCase, async: true
  use Oban.Testing, repo: DocPipeline.Repo

  import Phoenix.LiveViewTest

  alias DocPipeline.Projects
  alias DocPipeline.Workers.ProcessDocumentWorker

  test "full flow: project list -> upload -> process -> edit field -> correct type", %{conn: conn} do
    {:ok, project} = Projects.create_project(%{name: "Smoke Test Project", address: "1 Test Way"})

    {:ok, index_live, index_html} = live(conn, ~p"/projects")
    assert index_html =~ "Projects"
    assert index_html =~ "Smoke Test Project"

    {:ok, show_live, show_html} =
      index_live
      |> element("#projects td", "Smoke Test Project")
      |> render_click()
      |> follow_redirect(conn, ~p"/projects/#{project.id}")

    assert show_html =~ "Smoke Test Project"
    assert show_html =~ "Upload document"

    file =
      file_input(show_live, "form", :document, [
        %{
          name: "invoice.pdf",
          content: "This is a test invoice from ABC Corp for $5000",
          type: "application/pdf"
        }
      ])

    render_upload(file, "invoice.pdf")

    show_html =
      show_live
      |> form("form", %{})
      |> render_submit()

    assert show_html =~ "invoice.pdf"
    assert show_html =~ "uploaded"

    [document] = DocPipeline.Documents.list_documents_for_project(project.id)
    assert document.status == "uploaded"

    assert :ok = perform_job(ProcessDocumentWorker, %{document_id: document.id})

    {:ok, doc_live, doc_html} =
      live(conn, ~p"/projects/#{project.id}/documents/#{document.id}")

    assert doc_html =~ "processed"
    assert doc_html =~ "vendor_name"
    assert doc_html =~ "ABC Construction"

    {:ok, field} =
      DocPipeline.Documents.get_document(document.id)
      |> then(fn {:ok, d} -> {:ok, hd(d.fields)} end)

    doc_html =
      doc_live
      |> element("button[phx-click=edit_field][phx-value-id='#{field.id}']")
      |> render_click()

    assert doc_html =~ "phx-submit=\"save_field\""

    doc_html =
      doc_live
      |> form("form[phx-submit=save_field]", %{"field_id" => field.id, "value" => "Corrected Vendor"})
      |> render_submit()

    assert doc_html =~ "Corrected Vendor"
    assert doc_html =~ "Field updated"

    doc_html =
      doc_live
      |> form("form[phx-submit=correct_type]", %{"domain_type" => "budget"})
      |> render_submit()

    assert doc_html =~ "corrected to budget"

    {:ok, updated} = DocPipeline.Documents.get_document(document.id)
    assert updated.domain_type == "budget"
    assert updated.domain_type_source == "user"
  end
end
