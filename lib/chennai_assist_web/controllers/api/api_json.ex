defmodule ChennaiAssistWeb.API.ApiJSON do
  @moduledoc "JSON shapes returned by the mobile-app API (/api/v1)."

  alias ChennaiAssistWeb.SiteComponents

  def category(cat), do: %{key: cat, label: SiteComponents.category_label(cat), icon: SiteComponents.category_icon(cat)}

  def guide_summary(g),
    do: %{slug: g.slug, title: g.title, category: g.category, summary: g.summary}

  def guide(g), do: Map.put(guide_summary(g), :body, g.body)

  def photo(p),
    do: %{id: p.id, caption: p.caption, area: p.area, image_url: absolute(p.image_url), posted_at: p.inserted_at}

  def interview_summary(i) do
    %{
      slug: i.slug,
      title: i.title,
      person_name: i.person_name,
      occupation: i.occupation,
      area: i.area,
      photo_url: absolute(i.photo_url)
    }
  end

  def interview(i), do: Map.put(interview_summary(i), :body, i.body)

  def answer(q),
    do: %{id: q.id, category: q.category, question: q.body, answer: q.answer, answered_at: q.answered_at}

  def conversation(c),
    do: %{token: c.token, visitor_name: c.visitor_name, visitor_email: c.visitor_email, status: c.status}

  def message(m), do: %{id: m.id, sender: m.sender, body: m.body, sent_at: m.inserted_at}

  def errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  # Uploaded files are stored as "/uploads/...": give the app a full URL.
  defp absolute("/" <> _ = path), do: ChennaiAssistWeb.Endpoint.url() <> path
  defp absolute(other), do: other
end
