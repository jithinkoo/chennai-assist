defmodule ChennaiAssistWeb.API.HelpController do
  @moduledoc """
  Mobile-app help desk: ask a question, start a live chat, read and send chat
  messages. A chat is identified by its secret token, which the app keeps.
  New messages arrive in real time over the "chat:<token>" channel (/socket).
  """
  use ChennaiAssistWeb, :controller

  alias ChennaiAssist.{Chat, HelpDesk, Notifier}
  alias ChennaiAssistWeb.API.ApiJSON

  def ask(conn, params) do
    case HelpDesk.ask_question(Map.take(params, ~w(name email category body))) do
      {:ok, _question} -> conn |> put_status(:created) |> json(%{ok: true})
      {:error, changeset} -> unprocessable(conn, changeset)
    end
  end

  def start_chat(conn, params) do
    case Chat.start_conversation(Map.take(params, ~w(visitor_name visitor_email message))) do
      {:ok, conv} ->
        Notifier.chat_started(conv, url(~p"/chat/#{conv.token}"))

        conn
        |> put_status(:created)
        |> json(%{data: chat_payload(conv)})

      {:error, changeset} ->
        unprocessable(conn, changeset)
    end
  end

  def show_chat(conn, %{"token" => token}) do
    case Chat.get_conversation_by_token(token) do
      nil -> not_found(conn)
      conv -> json(conn, %{data: chat_payload(conv)})
    end
  end

  def send_message(conn, %{"token" => token} = params) do
    with %{} = conv <- Chat.get_conversation_by_token(token),
         {:ok, msg} <- Chat.send_message(conv, "visitor", params["body"] || "") do
      conn |> put_status(:created) |> json(%{data: ApiJSON.message(msg)})
    else
      nil -> not_found(conn)
      {:error, changeset} -> unprocessable(conn, changeset)
    end
  end

  defp chat_payload(conv) do
    conv
    |> ApiJSON.conversation()
    |> Map.put(:messages, Enum.map(Chat.list_messages(conv), &ApiJSON.message/1))
  end

  defp unprocessable(conn, changeset),
    do: conn |> put_status(:unprocessable_entity) |> json(%{errors: ApiJSON.errors(changeset)})

  defp not_found(conn), do: conn |> put_status(:not_found) |> json(%{error: "not_found"})
end
