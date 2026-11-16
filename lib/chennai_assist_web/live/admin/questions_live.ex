defmodule ChennaiAssistWeb.Admin.QuestionsLive do
  use ChennaiAssistWeb, :live_view
  import ChennaiAssistWeb.SiteComponents

  alias ChennaiAssist.HelpDesk

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: HelpDesk.subscribe_admin()

    {:ok,
     socket
     |> assign(:page_title, "Questions")
     |> assign(:editing, nil)
     |> assign(:questions, HelpDesk.list_questions())}
  end

  @impl true
  def handle_info({:question_updated, _}, socket),
    do: {:noreply, assign(socket, :questions, HelpDesk.list_questions())}

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    question = HelpDesk.get_question!(id)
    form = question |> HelpDesk.change_answer(%{}) |> to_form(as: :answer)
    {:noreply, socket |> assign(:editing, question.id) |> assign(:form, form)}
  end

  def handle_event("cancel", _, socket), do: {:noreply, assign(socket, :editing, nil)}

  def handle_event("save", %{"answer" => params}, socket) do
    question = HelpDesk.get_question!(socket.assigns.editing)

    case HelpDesk.answer_question(question, params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:editing, nil)
         |> assign(:questions, HelpDesk.list_questions())
         |> put_flash(:info, "Answer saved and emailed to the visitor.")}

      {:error, changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :answer))}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    {:ok, _} = id |> HelpDesk.get_question!() |> HelpDesk.delete_question()
    {:noreply, assign(socket, :questions, HelpDesk.list_questions())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="text-2xl font-bold text-zinc-900">Questions</h1>
    <p class="text-sm text-zinc-500">
      Unanswered first. Tick "Show on site" to publish the Q&A (without name or email).
    </p>
    <p :if={@questions == []} class="mt-6 text-zinc-500">No questions yet.</p>
    <div :for={q <- @questions} class="mt-4 rounded-2xl bg-white p-5 border border-zinc-200">
      <div class="flex flex-wrap items-center justify-between gap-2 text-xs text-zinc-500">
        <span>
          {category_icon(q.category)} {category_label(q.category)} · {q.name} ·
          <a href={"mailto:#{q.email}"} class="text-brand">{q.email}</a>
          · {Calendar.strftime(q.inserted_at, "%d %b %Y")}
        </span>
        <span>
          <span :if={is_nil(q.answer)} class="rounded-full bg-brand px-2 py-0.5 text-white">New</span>
          <span :if={q.answer && q.public} class="rounded-full bg-emerald-100 px-2 py-0.5 text-emerald-800">
            Public
          </span>
          <span :if={q.answer && !q.public} class="rounded-full bg-zinc-100 px-2 py-0.5">Answered, private</span>
        </span>
      </div>
      <p class="mt-2 font-semibold text-zinc-900 whitespace-pre-line">{q.body}</p>
      <div :if={q.answer && @editing != q.id} class="mt-3 text-zinc-700 border-l-4 border-sea pl-3">
        <p class="whitespace-pre-line">{q.answer}</p>
      </div>

      <div :if={@editing == q.id} class="mt-3">
        <.simple_form for={@form} id={"answer-#{q.id}"} phx-submit="save">
          <.input field={@form[:answer]} type="textarea" label="Answer" required />
          <.input field={@form[:public]} type="checkbox" label="Show on site" />
          <:actions>
            <.button phx-disable-with="Saving...">Save and email answer</.button>
            <button type="button" phx-click="cancel" class="text-sm">Cancel</button>
          </:actions>
        </.simple_form>
      </div>

      <div :if={@editing != q.id} class="mt-3 flex gap-4 text-sm">
        <button phx-click="edit" phx-value-id={q.id} class="font-semibold text-brand">
          {if q.answer, do: "Edit answer", else: "Answer"}
        </button>
        <button
          phx-click="delete"
          phx-value-id={q.id}
          data-confirm="Delete this question?"
          class="text-zinc-500"
        >
          Delete
        </button>
      </div>
    </div>
    """
  end
end
