defmodule ChennaiAssistWeb.Admin.NotificationsLive do
  @moduledoc "Set up and test Telegram and browser alerts."
  use ChennaiAssistWeb, :live_view

  alias ChennaiAssist.Telegram

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:page_title, "Alerts") |> assign_status()}
  end

  defp assign_status(socket) do
    assign(socket, configured: Telegram.configured?(), ready: Telegram.ready?())
  end

  @impl true
  def handle_event("link", _params, socket) do
    socket =
      case Telegram.link_latest_chat() do
        {:ok, name, :replies_on} ->
          put_flash(
            socket,
            :info,
            "Linked to #{name}'s Telegram. You can now swipe-reply to alerts in Telegram to answer visitors."
          )

        {:ok, name, :replies_off} ->
          put_flash(
            socket,
            :info,
            "Linked to #{name}'s Telegram for alerts. Replying from Telegram works only on the live https site."
          )

        {:error, :no_message} ->
          put_flash(socket, :error, "No message found. Open your bot in Telegram, press Start (or send \"hi\"), then try again.")

        {:error, {:http, 401, _}} ->
          put_flash(socket, :error, "Telegram rejected the bot token. Check TELEGRAM_BOT_TOKEN.")

        {:error, _} ->
          put_flash(socket, :error, "Could not reach Telegram. Try again in a minute.")
      end

    {:noreply, assign_status(socket)}
  end

  def handle_event("test", _params, socket) do
    socket =
      case Telegram.send_message(Telegram.chat_id(), "✅ Chennai Assist alerts are working.") do
        {:ok, _} -> put_flash(socket, :info, "Test sent. Check Telegram on your phone.")
        {:error, _} -> put_flash(socket, :error, "Test failed. Try linking again.")
      end

    {:noreply, socket}
  end

  def handle_event("test_browser", _params, socket) do
    ChennaiAssist.Alerts.chat_started(%{visitor_name: "Test visitor", visitor_email: "test@example.com", id: 0})
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="text-2xl font-bold text-zinc-900">Alerts</h1>
    <p class="mt-1 text-zinc-500">
      Get told the moment someone starts a chat, sends a message or asks a question.
    </p>

    <section class="mt-6 rounded-2xl bg-white border border-zinc-200 p-6">
      <div class="flex items-center justify-between gap-3">
        <h2 class="text-lg font-semibold text-zinc-900">📱 Telegram (on your phone)</h2>
        <span class={[
          "rounded-full px-3 py-1 text-xs font-semibold",
          @ready && "bg-emerald-100 text-emerald-800",
          !@ready && "bg-zinc-100 text-zinc-600"
        ]}>
          {if @ready, do: "On", else: "Off"}
        </span>
      </div>

      <ol :if={!@configured} class="mt-4 list-decimal pl-6 space-y-2 text-zinc-700">
        <li>In Telegram, open <b>@BotFather</b>, send <code>/newbot</code>, and choose a name.</li>
        <li>BotFather replies with a <b>token</b> (looks like <code>123456:ABC-...</code>).</li>
        <li>
          On Render, add it as the environment variable <code>TELEGRAM_BOT_TOKEN</code> and redeploy.
        </li>
        <li>Come back to this page to link your phone.</li>
      </ol>

      <div :if={@configured} class="mt-4 space-y-4">
        <p :if={!@ready} class="text-zinc-700">
          Bot token found. Now open your bot in Telegram, press <b>Start</b> (or send "hi"), then click
          <b>Link Telegram</b>.
        </p>
        <div :if={@ready} class="text-zinc-700 space-y-2">
          <p>Alerts go to your Telegram.</p>
          <p>
            <b>Reply from Telegram:</b>
            swipe-reply (or long-press → Reply) on an alert and type your answer. Chat replies appear
            instantly in the visitor's chat; question replies are saved and emailed to the visitor.
          </p>
          <p class="text-sm text-zinc-500">
            Updated the site or the bot token? Click Link Telegram again. To use a different phone,
            message the bot from it first.
          </p>
        </div>
        <div class="flex flex-wrap gap-3">
          <.button phx-click="link" phx-disable-with="Linking...">Link Telegram</.button>
          <.button :if={@ready} phx-click="test" phx-disable-with="Sending..." class="!bg-sea">
            Send test message
          </.button>
        </div>
      </div>
    </section>

    <section class="mt-6 rounded-2xl bg-white border border-zinc-200 p-6">
      <h2 class="text-lg font-semibold text-zinc-900">🔔 Browser (while an admin page is open)</h2>
      <p class="mt-2 text-zinc-700">
        Plays a sound, shows a desktop notification and flashes the tab title, even when you are in
        another tab. Keep any admin page open in a tab.
      </p>
      <p class="mt-2 text-sm text-zinc-500">
        Status in this browser: <span id="browser-alert-status" phx-update="ignore">checking…</span>
      </p>
      <div class="mt-4 flex flex-wrap gap-3">
        <button
          type="button"
          data-enable-alerts
          class="rounded-lg bg-brand px-3 py-2 text-sm font-semibold text-white hover:bg-orange-800"
        >
          Enable browser alerts
        </button>
        <.button phx-click="test_browser" class="!bg-sea">Test browser alert</.button>
      </div>
    </section>
    """
  end
end
