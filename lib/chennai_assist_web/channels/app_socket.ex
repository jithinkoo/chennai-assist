defmodule ChennaiAssistWeb.AppSocket do
  @moduledoc "WebSocket for the mobile app (/socket). Visitors join `chat:<token>`."
  use Phoenix.Socket

  channel "chat:*", ChennaiAssistWeb.ChatChannel

  @impl true
  def connect(_params, socket, _connect_info), do: {:ok, socket}

  @impl true
  def id(_socket), do: nil
end
