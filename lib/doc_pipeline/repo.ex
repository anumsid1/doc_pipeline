defmodule DocPipeline.Repo do
  use Ecto.Repo,
    otp_app: :doc_pipeline,
    adapter: Ecto.Adapters.Postgres
end
