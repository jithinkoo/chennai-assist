defmodule ChennaiAssistWeb.Admin.GuideLive.Index do
  use ChennaiAssistWeb, :live_view

  alias ChennaiAssist.Content
  alias ChennaiAssist.Content.Guide

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :guides, Content.list_guides())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Guide")
    |> assign(:guide, Content.get_guide!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Guide")
    |> assign(:guide, %Guide{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Guides")
    |> assign(:guide, nil)
  end

  @impl true
  def handle_info({ChennaiAssistWeb.Admin.GuideLive.FormComponent, {:saved, guide}}, socket) do
    {:noreply, stream_insert(socket, :guides, guide)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    guide = Content.get_guide!(id)
    {:ok, _} = Content.delete_guide(guide)

    {:noreply, stream_delete(socket, :guides, guide)}
  end
end
