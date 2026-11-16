defmodule ChennaiAssistWeb.Admin.InterviewLive.Index do
  use ChennaiAssistWeb, :live_view

  alias ChennaiAssist.Content
  alias ChennaiAssist.Content.Interview

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :interviews, Content.list_interviews())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Interview")
    |> assign(:interview, Content.get_interview!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Interview")
    |> assign(:interview, %Interview{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Interviews")
    |> assign(:interview, nil)
  end

  @impl true
  def handle_info({ChennaiAssistWeb.Admin.InterviewLive.FormComponent, {:saved, interview}}, socket) do
    {:noreply, stream_insert(socket, :interviews, interview)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    interview = Content.get_interview!(id)
    {:ok, _} = Content.delete_interview(interview)

    {:noreply, stream_delete(socket, :interviews, interview)}
  end
end
