defmodule DocPipeline.AI.Extractor do
  @moduledoc """
  Behaviour for extracting structured fields and line items from a
  document's raw text, given its classified domain type. Delegates to
  the adapter configured under `:doc_pipeline, :extractor_adapter`,
  defaulting to `DocPipeline.AI.Extractor.DefaultAdapter`.
  """

  @callback extract(domain_type :: String.t(), raw_text :: String.t()) ::
              {:ok, map()} | {:error, atom()}

  def extract(domain_type, raw_text) do
    adapter().extract(domain_type, raw_text)
  end

  defp adapter do
    Application.get_env(
      :doc_pipeline,
      :extractor_adapter,
      DocPipeline.AI.Extractor.DefaultAdapter
    )
  end
end
