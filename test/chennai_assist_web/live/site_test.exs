defmodule ChennaiAssistWeb.SiteTest do
  use ChennaiAssistWeb.ConnCase

  import Phoenix.LiveViewTest
  import ChennaiAssist.ContentFixtures

  alias ChennaiAssist.Chat

  test "home page links to chat and the guide", %{conn: conn} do
    {:ok, _lv, html} = live(conn, ~p"/")
    assert html =~ "Ask us anything"
    assert html =~ ~s|href="/chat"|
  end

  test "guide index and article pages show only published guides", %{conn: conn} do
    guide = guide_fixture(%{title: "Autos in Chennai", category: "transport", body: "Agree the fare.\n\n- Use apps"})
    _draft = guide_fixture(%{title: "Secret draft", published: false})

    {:ok, _lv, html} = live(conn, ~p"/guide?category=transport")
    assert html =~ "Autos in Chennai"
    refute html =~ "Secret draft"

    {:ok, _lv, html} = live(conn, ~p"/guide/#{guide.slug}")
    assert html =~ "Agree the fare."
    assert html =~ "<li>Use apps</li>"
  end

  test "visitor can ask a question", %{conn: conn} do
    {:ok, lv, _html} = live(conn, ~p"/ask")

    html =
      lv
      |> form("#ask-form",
        question: %{name: "Meena", email: "meena@example.com", category: "food", body: "Best filter coffee in Mylapore?"}
      )
      |> render_submit()

    assert html =~ "Your question has been sent"
  end

  describe "live chat" do
    test "visitor starts a chat and sees the admin's reply in real time", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/chat")

      lv
      |> form("#start-chat",
        start: %{visitor_name: "Ravi", visitor_email: "ravi@example.com", message: "Hello!"}
      )
      |> render_submit()

      path = assert_patch(lv)
      "/chat/" <> token = path
      conv = Chat.get_conversation_by_token(token)
      assert render(lv) =~ "Hello!"

      {:ok, _} = Chat.send_message(conv, "admin", "Vanakkam Ravi, how can I help?")
      assert render(lv) =~ "Vanakkam Ravi, how can I help?"
    end

    test "an unknown token redirects to the start page", %{conn: conn} do
      assert {:error, {:live_redirect, %{to: "/chat"}}} = live(conn, ~p"/chat/not-a-token")
    end
  end

  test "admin pages require login", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/users/log_in"}}} = live(conn, ~p"/admin/chats")
  end

  describe "admin" do
    setup :register_and_log_in_user

    test "admin sees and answers a chat live", %{conn: conn} do
      {:ok, conv} = Chat.start_conversation(%{"visitor_name" => "Lakshmi", "visitor_email" => "l@example.com"})
      {:ok, _} = Chat.send_message(conv, "visitor", "Is OMR safe at night?")

      {:ok, lv, html} = live(conn, ~p"/admin/chats/#{conv.id}")
      assert html =~ "Is OMR safe at night?"

      lv |> form("#reply-form", reply: %{body: "Mostly yes, use app cabs."}) |> render_submit()
      assert render(lv) =~ "Mostly yes, use app cabs."
      assert [_, %{sender: "admin"}] = Chat.list_messages(conv)
      refute Chat.get_conversation!(conv.id).unread_by_admin
    end
  end
end
