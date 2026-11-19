defmodule ChennaiAssistWeb.APITest do
  use ChennaiAssistWeb.ConnCase, async: true

  import ChennaiAssist.ContentFixtures

  alias ChennaiAssist.{Chat, Gallery, HelpDesk}

  describe "content" do
    test "guides: only published, filter by category, detail by slug", %{conn: conn} do
      g = guide_fixture(%{title: "Autos", category: "transport", body: "Use apps."})
      guide_fixture(%{title: "Draft", published: false})
      guide_fixture(%{title: "Idli", category: "food"})

      assert %{"data" => list} = conn |> get(~p"/api/v1/guides") |> json_response(200)
      assert list |> Enum.map(& &1["title"]) |> Enum.sort() == ["Autos", "Idli"]
      refute Map.has_key?(hd(list), "body")

      assert %{"data" => [%{"title" => "Autos"}]} =
               conn |> get(~p"/api/v1/guides?category=transport") |> json_response(200)

      assert %{"data" => %{"body" => "Use apps."}} =
               conn |> get(~p"/api/v1/guides/#{g.slug}") |> json_response(200)

      assert_error_sent 404, fn -> get(conn, ~p"/api/v1/guides/nope") end
    end

    test "categories", %{conn: conn} do
      assert %{"guide" => [%{"key" => "moving", "label" => "Moving to Chennai", "icon" => _} | _]} =
               conn |> get(~p"/api/v1/categories") |> json_response(200)
    end

    test "photos have absolute image URLs", %{conn: conn} do
      {:ok, _} = Gallery.create_photo(%{caption: "Marina", area: "Marina", image_url: "/uploads/a.jpg"})
      assert %{"data" => [%{"image_url" => url}]} = conn |> get(~p"/api/v1/photos") |> json_response(200)
      assert url =~ ~r{^https?://.+/uploads/a\.jpg$}
    end

    test "interviews: only published", %{conn: conn} do
      i = interview_fixture(%{title: "Mylapore life"})
      interview_fixture(%{title: "Hidden", published: false})
      assert %{"data" => [%{"title" => "Mylapore life"}]} = conn |> get(~p"/api/v1/interviews") |> json_response(200)
      assert %{"data" => %{"body" => _}} = conn |> get(~p"/api/v1/interviews/#{i.slug}") |> json_response(200)
    end

    test "answers: only public answered questions, no personal data", %{conn: conn} do
      {:ok, q} = HelpDesk.ask_question(%{"name" => "A", "email" => "a@example.com", "category" => "rent", "body" => "Rent in Adyar?"})
      {:ok, _} = HelpDesk.answer_question(q, %{"answer" => "Rs 25k", "public" => "true"})
      {:ok, _} = HelpDesk.ask_question(%{"name" => "B", "email" => "b@example.com", "category" => "rent", "body" => "Unanswered one"})

      assert %{"data" => [answer]} = conn |> get(~p"/api/v1/answers") |> json_response(200)
      assert answer["question"] == "Rent in Adyar?"
      refute Map.has_key?(answer, "email")
      refute Map.has_key?(answer, "name")
    end
  end

  describe "help desk" do
    test "ask a question", %{conn: conn} do
      body = %{name: "Meena", email: "m@example.com", category: "food", body: "Best filter coffee?"}
      assert %{"ok" => true} = conn |> post(~p"/api/v1/questions", body) |> json_response(201)

      assert %{"errors" => %{"email" => _}} =
               conn |> post(~p"/api/v1/questions", %{body | email: "bad"}) |> json_response(422)
    end

    test "chat: start, read, send", %{conn: conn} do
      start = %{visitor_name: "Ravi", visitor_email: "r@example.com", message: "Hi!"}
      assert %{"data" => %{"token" => token, "messages" => [%{"body" => "Hi!", "sender" => "visitor"}]}} =
               conn |> post(~p"/api/v1/chats", start) |> json_response(201)

      conv = Chat.get_conversation_by_token(token)
      {:ok, _} = Chat.send_message(conv, "admin", "Vanakkam!")

      assert %{"data" => %{"messages" => [_, %{"sender" => "admin", "body" => "Vanakkam!"}]}} =
               conn |> get(~p"/api/v1/chats/#{token}") |> json_response(200)

      assert %{"data" => %{"body" => "Thanks"}} =
               conn |> post(~p"/api/v1/chats/#{token}/messages", %{body: "Thanks"}) |> json_response(201)

      assert conn |> post(~p"/api/v1/chats/#{token}/messages", %{body: " "}) |> json_response(422)
      assert conn |> get(~p"/api/v1/chats/wrong-token") |> json_response(404)
    end
  end
end
