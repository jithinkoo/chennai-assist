defmodule ChennaiAssist.Telegram do
  @moduledoc """
  Sends help-desk alerts to the admin's phone through a Telegram bot.

  Setup: create a bot with @BotFather, put its token in TELEGRAM_BOT_TOKEN,
  send any message to the bot from your phone, then click "Link Telegram" on
  /admin/notifications (or set TELEGRAM_CHAT_ID yourself).
  """
  require Logger

  alias ChennaiAssist.Settings

  @chat_setting "telegram_chat_id"

  def token, do: Application.get_env(:chennai_assist, :telegram_bot_token)
  defp api_base, do: Application.get_env(:chennai_assist, :telegram_api, "https://api.telegram.org")

  @doc "True when a bot token is configured."
  def configured?, do: present?(token())

  @doc "The chat that receives alerts: TELEGRAM_CHAT_ID, or the one linked from the admin page."
  def chat_id do
    env = Application.get_env(:chennai_assist, :telegram_chat_id)
    if present?(env), do: env, else: Settings.get(@chat_setting)
  end

  @doc "True when alerts will actually be sent."
  def ready?, do: configured?() and present?(chat_id())

  @doc "Sends `text` to the admin in the background. Never raises."
  def notify(text) do
    if ready?() do
      chat = chat_id()
      Task.start(fn -> send_message(chat, text) end)
    end

    :ok
  end

  def send_message(chat_id, text) do
    request("sendMessage", %{chat_id: chat_id, text: text, disable_web_page_preview: true})
  end

  @doc """
  Finds the private chat that most recently messaged the bot and saves it as
  the alert destination. Returns `{:ok, name}` or `{:error, reason}`.
  """
  def link_latest_chat do
    with {:ok, %{"result" => updates}} <- request("getUpdates", %{}) do
      chat =
        updates
        |> Enum.reverse()
        |> Enum.find_value(fn update ->
          case get_in(update, ["message", "chat"]) do
            %{"type" => "private", "id" => id} = chat -> {id, chat["first_name"] || "you"}
            _ -> nil
          end
        end)

      case chat do
        {id, name} ->
          {:ok, _} = Settings.put(@chat_setting, to_string(id))
          {:ok, name}

        nil ->
          {:error, :no_message}
      end
    end
  end

  defp request(method, body) do
    if configured?() do
      req =
        Finch.build(
          :post,
          "#{api_base()}/bot#{token()}/#{method}",
          [{"content-type", "application/json"}],
          Jason.encode!(body)
        )

      case Finch.request(req, ChennaiAssist.Finch, receive_timeout: 10_000) do
        {:ok, %Finch.Response{status: 200, body: resp}} ->
          {:ok, Jason.decode!(resp)}

        {:ok, %Finch.Response{status: status, body: resp}} ->
          description = with {:ok, %{"description" => d}} <- Jason.decode(resp), do: d
          Logger.warning("Telegram #{method} failed: HTTP #{status} #{inspect(description)}")
          {:error, {:http, status, description}}

        {:error, error} ->
          # Never log the URL: it contains the bot token.
          Logger.warning("Telegram #{method} failed: #{Exception.message(error)}")
          {:error, :unreachable}
      end
    else
      {:error, :not_configured}
    end
  end

  defp present?(value), do: is_binary(value) and value != ""
end
