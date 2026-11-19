defmodule ChennaiAssistWeb.API.ContentController do
  @moduledoc "Read-only content for the mobile app: guide, photos, interviews, answers."
  use ChennaiAssistWeb, :controller

  alias ChennaiAssist.{Content, Gallery, HelpDesk}
  alias ChennaiAssist.Content.Guide
  alias ChennaiAssist.HelpDesk.Question
  alias ChennaiAssistWeb.API.ApiJSON

  def categories(conn, _params) do
    json(conn, %{
      guide: Enum.map(Guide.categories(), &ApiJSON.category/1),
      question: Enum.map(Question.categories(), &ApiJSON.category/1)
    })
  end

  def guides(conn, params) do
    category = if params["category"] in Guide.categories(), do: params["category"]
    json(conn, %{data: Enum.map(Content.list_published_guides(category), &ApiJSON.guide_summary/1)})
  end

  def guide(conn, %{"slug" => slug}) do
    json(conn, %{data: ApiJSON.guide(Content.get_published_guide_by_slug!(slug))})
  end

  def photos(conn, _params) do
    json(conn, %{data: Enum.map(Gallery.list_photos(), &ApiJSON.photo/1)})
  end

  def interviews(conn, _params) do
    json(conn, %{data: Enum.map(Content.list_published_interviews(), &ApiJSON.interview_summary/1)})
  end

  def interview(conn, %{"slug" => slug}) do
    json(conn, %{data: ApiJSON.interview(Content.get_published_interview_by_slug!(slug))})
  end

  def answers(conn, params) do
    category = if params["category"] in Question.categories(), do: params["category"]
    json(conn, %{data: Enum.map(HelpDesk.list_public_answers(category), &ApiJSON.answer/1)})
  end
end
