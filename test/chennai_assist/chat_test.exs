defmodule ChennaiAssist.ChatTest do
  use ChennaiAssist.DataCase, async: true

  alias ChennaiAssist.Chat

  @visitor %{"visitor_name" => "Priya", "visitor_email" => "priya@example.com"}

  test "start_conversation/1 creates an open, unread conversation with a secret token" do
    assert {:ok, conv} = Chat.start_conversation(@visitor)
    assert conv.status == "open"
    assert conv.unread_by_admin
    assert byte_size(conv.token) >= 30
    assert Chat.get_conversation_by_token(conv.token).id == conv.id
  end

  test "start_conversation/1 requires a valid email" do
    assert {:error, cs} = Chat.start_conversation(%{@visitor | "visitor_email" => "nope"})
    assert %{visitor_email: ["enter a valid email"]} = errors_on(cs)
  end

  test "messages are broadcast and set unread state" do
    {:ok, conv} = Chat.start_conversation(@visitor)
    {:ok, conv} = Chat.mark_read(conv)
    Chat.subscribe(conv)
    Chat.subscribe_admin()

    {:ok, msg} = Chat.send_message(conv, "visitor", "  Where should I stay near Guindy?  ")
    assert msg.body == "Where should I stay near Guindy?"
    assert_receive {:new_message, %{id: id}} when id == msg.id
    assert_receive {:conversation_updated, %{unread_by_admin: true}}

    {:ok, _} = Chat.send_message(Chat.get_conversation!(conv.id), "admin", "Try Velachery or Adyar.")
    assert_receive {:conversation_updated, %{unread_by_admin: false}}

    assert [%{sender: "visitor"}, %{sender: "admin"}] = Chat.list_messages(conv)
  end

  test "a visitor message re-opens a closed chat; empty and spoofed messages are rejected" do
    {:ok, conv} = Chat.start_conversation(@visitor)
    {:ok, conv} = Chat.set_status(conv, "closed")
    assert {:error, _} = Chat.send_message(conv, "visitor", "   ")
    assert {:error, _} = Chat.send_message(conv, "robot", "hi")

    {:ok, _} = Chat.send_message(conv, "visitor", "One more question")
    assert Chat.get_conversation!(conv.id).status == "open"
  end
end
