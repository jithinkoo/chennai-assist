defmodule ChennaiAssist.Content do
  @moduledoc """
  The Content context.
  """

  import Ecto.Query, warn: false
  alias ChennaiAssist.Repo

  alias ChennaiAssist.Content.Guide

  @doc """
  Returns the list of guides.

  ## Examples

      iex> list_guides()
      [%Guide{}, ...]

  """
  def list_guides do
    Repo.all(Guide)
  end

  @doc """
  Gets a single guide.

  Raises `Ecto.NoResultsError` if the Guide does not exist.

  ## Examples

      iex> get_guide!(123)
      %Guide{}

      iex> get_guide!(456)
      ** (Ecto.NoResultsError)

  """
  def get_guide!(id), do: Repo.get!(Guide, id)

  @doc """
  Creates a guide.

  ## Examples

      iex> create_guide(%{field: value})
      {:ok, %Guide{}}

      iex> create_guide(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_guide(attrs \\ %{}) do
    %Guide{}
    |> Guide.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a guide.

  ## Examples

      iex> update_guide(guide, %{field: new_value})
      {:ok, %Guide{}}

      iex> update_guide(guide, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_guide(%Guide{} = guide, attrs) do
    guide
    |> Guide.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a guide.

  ## Examples

      iex> delete_guide(guide)
      {:ok, %Guide{}}

      iex> delete_guide(guide)
      {:error, %Ecto.Changeset{}}

  """
  def delete_guide(%Guide{} = guide) do
    Repo.delete(guide)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking guide changes.

  ## Examples

      iex> change_guide(guide)
      %Ecto.Changeset{data: %Guide{}}

  """
  def change_guide(%Guide{} = guide, attrs \\ %{}) do
    Guide.changeset(guide, attrs)
  end

  alias ChennaiAssist.Content.Interview

  @doc """
  Returns the list of interviews.

  ## Examples

      iex> list_interviews()
      [%Interview{}, ...]

  """
  def list_interviews do
    Repo.all(Interview)
  end

  @doc """
  Gets a single interview.

  Raises `Ecto.NoResultsError` if the Interview does not exist.

  ## Examples

      iex> get_interview!(123)
      %Interview{}

      iex> get_interview!(456)
      ** (Ecto.NoResultsError)

  """
  def get_interview!(id), do: Repo.get!(Interview, id)

  @doc """
  Creates a interview.

  ## Examples

      iex> create_interview(%{field: value})
      {:ok, %Interview{}}

      iex> create_interview(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_interview(attrs \\ %{}) do
    %Interview{}
    |> Interview.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a interview.

  ## Examples

      iex> update_interview(interview, %{field: new_value})
      {:ok, %Interview{}}

      iex> update_interview(interview, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_interview(%Interview{} = interview, attrs) do
    interview
    |> Interview.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a interview.

  ## Examples

      iex> delete_interview(interview)
      {:ok, %Interview{}}

      iex> delete_interview(interview)
      {:error, %Ecto.Changeset{}}

  """
  def delete_interview(%Interview{} = interview) do
    Repo.delete(interview)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking interview changes.

  ## Examples

      iex> change_interview(interview)
      %Ecto.Changeset{data: %Interview{}}

  """
  def change_interview(%Interview{} = interview, attrs \\ %{}) do
    Interview.changeset(interview, attrs)
  end

  ## Public site queries (published content only)

  def list_published_guides(category \\ nil) do
    Guide
    |> where([g], g.published)
    |> then(fn q -> if category, do: where(q, [g], g.category == ^category), else: q end)
    |> order_by([g], asc: g.category, asc: g.title)
    |> Repo.all()
  end

  def get_published_guide_by_slug!(slug),
    do: Repo.get_by!(Guide, slug: slug, published: true)

  def list_published_interviews do
    Interview
    |> where([i], i.published)
    |> order_by([i], desc: i.inserted_at)
    |> Repo.all()
  end

  def get_published_interview_by_slug!(slug),
    do: Repo.get_by!(Interview, slug: slug, published: true)
end
