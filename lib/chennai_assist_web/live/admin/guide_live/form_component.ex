defmodule ChennaiAssistWeb.Admin.GuideLive.FormComponent do
  use ChennaiAssistWeb, :live_component

  alias ChennaiAssist.Content

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage guide records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="guide-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:slug]} type="text" label="Slug (web address, e.g. best-areas-for-families)" />
        <.input
          field={@form[:category]}
          type="select"
          label="Category"
          options={ChennaiAssistWeb.SiteComponents.category_options(ChennaiAssist.Content.Guide.categories())}
        />
        <.input field={@form[:summary]} type="textarea" label="Summary (one or two sentences)" />
        <.input
          field={@form[:body]}
          type="textarea"
          label="Body (blank line = new paragraph, '- ' = bullet point)"
          class="min-h-[24rem]"
        />
        <.input field={@form[:published]} type="checkbox" label="Published" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Guide</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{guide: guide} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Content.change_guide(guide))
     end)}
  end

  @impl true
  def handle_event("validate", %{"guide" => guide_params}, socket) do
    changeset = Content.change_guide(socket.assigns.guide, guide_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"guide" => guide_params}, socket) do
    save_guide(socket, socket.assigns.action, guide_params)
  end

  defp save_guide(socket, :edit, guide_params) do
    case Content.update_guide(socket.assigns.guide, guide_params) do
      {:ok, guide} ->
        notify_parent({:saved, guide})

        {:noreply,
         socket
         |> put_flash(:info, "Guide updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_guide(socket, :new, guide_params) do
    case Content.create_guide(guide_params) do
      {:ok, guide} ->
        notify_parent({:saved, guide})

        {:noreply,
         socket
         |> put_flash(:info, "Guide created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
