defmodule ChennaiAssistWeb.ChatChannelTest do
  use ChennaiAssist.DataCase, async: true

  import Phoenix.ChannelTest

  alias ChennaiAssist.Chat
  alias ChennaiAssistWeb.{AppSocket, ChatChannel}

  @endpoint ChennaiAssistWeb.Endpoint

  setup do
    {:ok, conv} = Chat.start_conversation(%{"visitor_name" => "Ravi", "visitor_email" => "r@example.com"})
    {:ok, socket} = connect(AppSocket, %{})
    %{conv: conv, socket: socket}
  end

  test "joining needs a valid token", %{socket: socket} do
    assert {:error, %{reason: "not_found"}} = subscribe_and_join(socket, ChatChannel, "chat:nope")
  end

  test "admin replies are pushed live; the app can send", %{conv: conv, socket: socket} do
    {:ok, %{status: "open"}, socket} = subscribe_and_join(socket, ChatChannel, "chat:#{conv.token}")

    {:ok, _} = Chat.send_message(conv, "admin", "Vanakkam!")
    assert_push "new_message", %{sender: "admin", body: "Vanakkam!"}

    ref = push(socket, "send", %{"body" => "Thanks!"})
    assert_reply ref, :ok, %{sender: "visitor", body: "Thanks!"}
    assert_push "new_message", %{sender: "visitor", body: "Thanks!"}

    {:ok, _} = Chat.set_status(Chat.get_conversation!(conv.id), "closed")
    assert_push "status", %{status: "closed"}
  end
end
