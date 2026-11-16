defmodule ChennaiAssistWeb.SiteComponents do
  @moduledoc "Small components shared by the public site and admin."
  use Phoenix.Component

  @labels %{
    "moving" => {"Moving to Chennai", "🧳"},
    "rent" => {"Rent & areas", "🏠"},
    "transport" => {"Autos & transport", "🛺"},
    "weather" => {"Weather", "🌦️"},
    "food" => {"Food", "🍛"},
    "culture" => {"Culture & festivals", "🪔"},
    "people" => {"People & language", "🤝"},
    "politics" => {"Politics explained", "🏛️"},
    "areas" => {"Neighbourhoods", "🗺️"},
    "jobs" => {"Jobs & interviews", "💼"},
    "other" => {"Something else", "❓"}
  }

  def category_label(cat), do: @labels |> Map.get(cat, {cat, ""}) |> elem(0)
  def category_icon(cat), do: @labels |> Map.get(cat, {cat, "📍"}) |> elem(1)

  def category_options(categories), do: Enum.map(categories, &{category_label(&1), &1})

  @doc """
  Renders plain text written by the admin as readable paragraphs.
  A blank line starts a new paragraph, lines beginning with "- " become a list,
  and a short line with no full stop followed by text becomes a sub-heading.
  The text is always HTML-escaped.
  """
  attr :text, :string, required: true

  def prose(assigns) do
    assigns = assign(assigns, :blocks, blocks(assigns.text || ""))

    ~H"""
    <div class="space-y-4 leading-7 text-zinc-700">
      <%= for block <- @blocks do %>
        <%= case block do %>
          <% {:list, items} -> %>
            <ul class="list-disc pl-6 space-y-1">
              <li :for={item <- items}>{item}</li>
            </ul>
          <% {:heading, text, rest} -> %>
            <h3 class="text-lg font-semibold text-zinc-900 pt-2">{text}</h3>
            <p :if={rest != ""}>{rest}</p>
          <% {:para, text} -> %>
            <p>{text}</p>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp blocks(text) do
    text
    |> String.replace("\r\n", "\n")
    |> String.split(~r/\n\s*\n/, trim: true)
    |> Enum.flat_map(&block/1)
  end

  defp block(chunk) do
    lines = chunk |> String.split("\n") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

    groups = Enum.chunk_by(lines, &list_item?/1)
    multi? = length(lines) > 1

    Enum.flat_map(groups, fn
      [first | _] = group ->
        cond do
          list_item?(first) -> [{:list, Enum.map(group, &unbullet/1)}]
          multi? and heading?(first) -> [{:heading, first, Enum.join(tl(group), " ")}]
          true -> [{:para, Enum.join(group, " ")}]
        end
    end)
  end

  defp list_item?(line), do: String.starts_with?(line, "- ")
  defp unbullet(line), do: String.replace_prefix(line, "- ", "")

  defp heading?(line), do: String.length(line) <= 60 and not String.ends_with?(line, [".", ":", "?", "!"])
end
