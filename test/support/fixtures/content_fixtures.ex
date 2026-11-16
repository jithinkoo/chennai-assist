defmodule ChennaiAssist.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ChennaiAssist.Content` context.
  """

  @doc """
  Generate a unique guide slug.
  """
  def unique_guide_slug, do: "some-slug-#{System.unique_integer([:positive])}"

  @doc """
  Generate a guide.
  """
  def guide_fixture(attrs \\ %{}) do
    {:ok, guide} =
      attrs
      |> Enum.into(%{
        body: "some body",
        category: "food",
        published: true,
        slug: unique_guide_slug(),
        summary: "some summary",
        title: "some title"
      })
      |> ChennaiAssist.Content.create_guide()

    guide
  end

  @doc """
  Generate a unique interview slug.
  """
  def unique_interview_slug, do: "some-slug-#{System.unique_integer([:positive])}"

  @doc """
  Generate a interview.
  """
  def interview_fixture(attrs \\ %{}) do
    {:ok, interview} =
      attrs
      |> Enum.into(%{
        area: "some area",
        body: "some body",
        occupation: "some occupation",
        person_name: "some person_name",
        photo_url: "some photo_url",
        published: true,
        slug: unique_interview_slug(),
        title: "some title"
      })
      |> ChennaiAssist.Content.create_interview()

    interview
  end
end
