defmodule DocPipelineWeb.PageController do
  use DocPipelineWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
