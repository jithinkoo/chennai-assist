defmodule ChennaiAssist.HelpDesk do
  @moduledoc """
  "Ask a question": visitors post questions with their email, the admin
  answers, and answered questions marked public appear on the site.
  """
  import Ecto.Query, warn: false

  alias ChennaiAssist.{Notifier, Repo}
  alias ChennaiAssist.HelpDesk.Question

  @pubsub ChennaiAssist.PubSub
  @admin_topic "helpdesk:admin"

  def subscribe_admin, do: Phoenix.PubSub.subscribe(@pubsub, @admin_topic)

  def list_public_answers(category \\ nil) do
    Question
    |> where([q], q.public and not is_nil(q.answer))
    |> then(fn query -> if category, do: where(query, [q], q.category == ^category), else: query end)
    |> order_by([q], desc: q.answered_at)
    |> limit(100)
    |> Repo.all()
  end

  @doc "All questions for the admin, unanswered first, newest first."
  def list_questions do
    from(q in Question,
      order_by: [asc: not is_nil(q.answer), desc: q.inserted_at],
      limit: 300
    )
    |> Repo.all()
  end

  def count_unanswered do
    from(q in Question, where: is_nil(q.answer)) |> Repo.aggregate(:count)
  end

  def get_question!(id), do: Repo.get!(Question, id)

  def change_ask(attrs \\ %{}), do: Question.ask_changeset(%Question{}, attrs)

  def ask_question(attrs) do
    %Question{}
    |> Question.ask_changeset(attrs)
    |> Repo.insert()
    |> tap(fn
      {:ok, question} ->
        Phoenix.PubSub.broadcast(@pubsub, @admin_topic, {:question_updated, question})
        Notifier.question_received(question)

      _ ->
        :ok
    end)
  end

  def change_answer(%Question{} = question, attrs \\ %{}),
    do: Question.answer_changeset(question, attrs)

  def answer_question(%Question{} = question, attrs) do
    question
    |> Question.answer_changeset(attrs)
    |> Repo.update()
    |> tap(fn
      {:ok, question} ->
        Phoenix.PubSub.broadcast(@pubsub, @admin_topic, {:question_updated, question})
        Notifier.question_answered(question)

      _ ->
        :ok
    end)
  end

  def delete_question(%Question{} = question), do: Repo.delete(question)
end
