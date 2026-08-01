defmodule DocPipelineWeb.Schema do
  @moduledoc """
  Root GraphQL schema, served at `/graphql` (and browsable at
  `/graphiql`). Assembles the query and mutation fields defined in
  `DocPipelineWeb.Schema.ProjectTypes` and `DocPipelineWeb.Schema.DocumentTypes`.
  """

  use Absinthe.Schema

  import_types(DocPipelineWeb.Schema.ProjectTypes)
  import_types(DocPipelineWeb.Schema.DocumentTypes)

  query do
    import_fields(:project_queries)
    import_fields(:document_queries)
  end

  mutation do
    import_fields(:project_mutations)
    import_fields(:document_mutations)
  end
end
