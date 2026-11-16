defmodule ChennaiAssist.HelpDeskTest do
  use ChennaiAssist.DataCase, async: true

  alias ChennaiAssist.HelpDesk

  @ask %{
    "name" => "Arjun",
    "email" => "arjun@example.com",
    "category" => "rent",
    "body" => "What is a fair rent for a 2BHK in Velachery?"
  }

  test "ask, answer and publish a question" do
    {:ok, q} = HelpDesk.ask_question(@ask)
    assert HelpDesk.count_unanswered() == 1
    assert HelpDesk.list_public_answers() == []

    {:ok, q} = HelpDesk.answer_question(q, %{"answer" => "Roughly Rs 18-28k.", "public" => "true"})
    assert q.answered_at
    assert HelpDesk.count_unanswered() == 0
    assert [%{id: id}] = HelpDesk.list_public_answers("rent")
    assert id == q.id
    assert HelpDesk.list_public_answers("food") == []
  end

  test "answered but private questions stay off the site" do
    {:ok, q} = HelpDesk.ask_question(@ask)
    {:ok, _} = HelpDesk.answer_question(q, %{"answer" => "Private reply", "public" => "false"})
    assert HelpDesk.list_public_answers() == []
  end

  test "validates the visitor's input" do
    assert {:error, cs} = HelpDesk.ask_question(%{@ask | "email" => "x", "body" => "short"})
    errors = errors_on(cs)
    assert errors.email
    assert errors.body
  end
end
