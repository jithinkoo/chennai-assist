defmodule ChennaiAssistWeb.Admin.InterviewLive.FormComponent do
  use ChennaiAssistWeb, :live_component

  alias ChennaiAssist.Content

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage interview records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="interview-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:slug]} type="text" label="Slug" />
        <.input field={@form[:person_name]} type="text" label="Person name" />
        <.input field={@form[:occupation]} type="text" label="Occupation" />
        <.input field={@form[:area]} type="text" label="Area" />
        <.input
          field={@form[:body]}
          type="textarea"
          label="Interview (blank line = new paragraph)"
          class="min-h-[24rem]"
        />
        <.input
          field={@form[:photo_url]}
          type="text"
          label="Photo URL (upload on the Photos page, then paste its /uploads/... address)"
        />
        <.input field={@form[:published]} type="checkbox" label="Published" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Interview</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{interview: interview} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Content.change_interview(interview))
     end)}
  end

  @impl true
  def handle_event("validate", %{"interview" => interview_params}, socket) do
    changeset = Content.change_interview(socket.assigns.interview, interview_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"interview" => interview_params}, socket) do
    save_interview(socket, socket.assigns.action, interview_params)
  end

  defp save_interview(socket, :edit, interview_params) do
    case Content.update_interview(socket.assigns.interview, interview_params) do
      {:ok, interview} ->
        notify_parent({:saved, interview})

        {:noreply,
         socket
         |> put_flash(:info, "Interview updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_interview(socket, :new, interview_params) do
    case Content.create_interview(interview_params) do
      {:ok, interview} ->
        notify_parent({:saved, interview})

        {:noreply,
         socket
         |> put_flash(:info, "Interview created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
