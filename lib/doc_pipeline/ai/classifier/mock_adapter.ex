defmodule DocPipeline.AI.Classifier.MockAdapter do
  @moduledoc """
  Test-only classifier adapter that keyword-matches the raw text
  instead of calling the Claude API. Used via `:doc_pipeline, :classifier_adapter`
  in `config/test.exs`.
  """

  @behaviour DocPipeline.AI.Classifier

  def classify(raw_text) do
    cond do
      String.contains?(raw_text, "invoice") -> {:ok, "invoice"}
      String.contains?(raw_text, "budget") -> {:ok, "budget"}
      String.contains?(raw_text, "change_order") -> {:ok, "change_order"}
      String.contains?(raw_text, "pay_application") -> {:ok, "pay_application"}
      true -> {:ok, "invoice"}
    end
  end
end
