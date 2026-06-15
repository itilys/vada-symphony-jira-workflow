defmodule SymphonyElixir.Jira.ADF do
  @moduledoc """
  Minimal Atlassian Document Format to plain text conversion.

  This is intentionally small for the read-only Jira adapter. It extracts readable text for prompts
  without trying to preserve every rich-text mark or layout detail.
  """

  @spec to_text(term()) :: String.t() | nil
  def to_text(nil), do: nil

  def to_text(value) when is_binary(value) do
    normalize_output(value)
  end

  def to_text(%{} = document) do
    document
    |> node_to_text()
    |> normalize_output()
  end

  def to_text(_value), do: nil

  defp node_to_text(%{"type" => "doc", "content" => content}) when is_list(content) do
    block_nodes_to_text(content)
  end

  defp node_to_text(%{"type" => "paragraph", "content" => content}) when is_list(content) do
    inline_nodes_to_text(content) <> "\n\n"
  end

  defp node_to_text(%{"type" => "heading", "content" => content}) when is_list(content) do
    inline_nodes_to_text(content) <> "\n\n"
  end

  defp node_to_text(%{"type" => "blockquote", "content" => content}) when is_list(content) do
    block_nodes_to_text(content) <> "\n"
  end

  defp node_to_text(%{"type" => "codeBlock", "content" => content}) when is_list(content) do
    inline_nodes_to_text(content) <> "\n\n"
  end

  defp node_to_text(%{"type" => type, "content" => content})
       when type in ["bulletList", "orderedList"] and is_list(content) do
    Enum.map_join(content, "", &list_item_to_text/1) <> "\n"
  end

  defp node_to_text(%{"type" => "listItem", "content" => content}) when is_list(content) do
    block_nodes_to_text(content)
  end

  defp node_to_text(%{"type" => "text", "text" => text}) when is_binary(text), do: text
  defp node_to_text(%{"type" => "hardBreak"}), do: "\n"

  defp node_to_text(%{"content" => content}) when is_list(content) do
    block_nodes_to_text(content)
  end

  defp node_to_text(_node), do: ""

  defp block_nodes_to_text(nodes) when is_list(nodes), do: Enum.map_join(nodes, "", &node_to_text/1)
  defp inline_nodes_to_text(nodes) when is_list(nodes), do: Enum.map_join(nodes, "", &node_to_text/1)

  defp list_item_to_text(%{"content" => content}) when is_list(content) do
    content =
      content
      |> block_nodes_to_text()
      |> String.split("\n", trim: true)
      |> Enum.join("\n  ")

    "- " <> content <> "\n"
  end

  defp list_item_to_text(node), do: "- " <> node_to_text(node) <> "\n"

  defp normalize_output(value) when is_binary(value) do
    value
    |> String.replace(~r/[ \t]+\n/, "\n")
    |> String.replace(~r/\n{3,}/, "\n\n")
    |> String.trim()
    |> case do
      "" -> nil
      text -> text
    end
  end
end
