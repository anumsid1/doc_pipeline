defmodule DocPipeline.AI.Classifier do
  @moduledoc """
  Behaviour for classifying a document's raw text into one of the
  supported domain types (invoice, budget, change_order, pay_application).
  Delegates to the adapter configured under `:doc_pipeline, :classifier_adapter`,
  defaulting to `DocPipeline.AI.Classifier.DefaultAdapter`.
  """

  @callback classify(raw_text :: String.t()) :: {:ok, String.t()} | {:error, atom()}

  def classify(raw_text) do
    adapter().classify(raw_text)
  end

  defp adapter do
    Application.get_env(
      :doc_pipeline,
      :classifier_adapter,
      DocPipeline.AI.Classifier.DefaultAdapter
    )
  end
end
