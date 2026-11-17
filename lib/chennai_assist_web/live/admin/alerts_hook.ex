defmodule ChennaiAssistWeb.Admin.AlertsHook do
  @moduledoc """
  Mounted on every admin page: forwards help-desk alerts to the browser as an
  "admin-alert" event, which app.js turns into a sound, a desktop notification
  and a blinking tab title.
  """
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    if connected?(socket), do: ChennaiAssist.Alerts.subscribe()

    {:cont,
     attach_hook(socket, :admin_alerts, :handle_info, fn
       {:admin_alert, alert}, socket -> {:halt, push_event(socket, "admin-alert", alert)}
       _other, socket -> {:cont, socket}
     end)}
  end
end
