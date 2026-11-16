defmodule ChennaiAssist.Notifier do
  @moduledoc """
  Email notifications for the help desk.

  In development, emails appear at /dev/mailbox. In production configure a
  real Swoosh adapter (see README). Delivery runs in a background task so a
  mail failure never breaks the chat or the question form.
  """
  import Swoosh.Email
  require Logger

  alias ChennaiAssist.Mailer

  defp admin_email, do: Application.get_env(:chennai_assist, :admin_email)

  defp sender do
    {"Chennai Assist", Application.get_env(:chennai_assist, :mail_from, "noreply@chennai-assist.local")}
  end

  defp deliver(nil, _subject, _body), do: :ok

  defp deliver(to, subject, body) do
    email = new() |> to(to) |> from(sender()) |> subject(subject) |> text_body(body)

    Task.start(fn ->
      case Mailer.deliver(email) do
        {:ok, _} -> :ok
        {:error, reason} -> Logger.warning("email to help desk recipient failed: #{inspect(reason)}")
      end
    end)

    :ok
  end

  @doc "Sends the visitor their private chat link, and alerts the admin."
  def chat_started(conversation, chat_url) do
    deliver(conversation.visitor_email, "Your Chennai Assist chat", """
    Hi #{conversation.visitor_name},

    Thanks for contacting Chennai Assist. You can return to your chat any time here:

    #{chat_url}

    Keep this link private: anyone with it can read the conversation.
    """)

    deliver(admin_email(), "New chat from #{conversation.visitor_name}", """
    #{conversation.visitor_name} (#{conversation.visitor_email}) started a chat.
    Open the admin chats page to reply.
    """)
  end

  def question_received(question) do
    deliver(admin_email(), "New question: #{question.category}", """
    From: #{question.name} (#{question.email})

    #{question.body}
    """)
  end

  def question_answered(question) do
    deliver(question.email, "Your Chennai question has an answer", """
    Hi #{question.name},

    You asked:
    #{question.body}

    Our answer:
    #{question.answer}

    Chennai Assist
    """)
  end
end
