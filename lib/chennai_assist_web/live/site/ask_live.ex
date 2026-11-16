defmodule ChennaiAssistWeb.Site.AskLive do
  use ChennaiAssistWeb, :live_view
  import ChennaiAssistWeb.SiteComponents

  alias ChennaiAssist.HelpDesk
  alias ChennaiAssist.HelpDesk.Question

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Ask a question")
     |> assign(:submitted, false)
     |> assign(:category_options, category_options(Question.categories()))
     |> assign(:answers, HelpDesk.list_public_answers())
     |> assign_form(HelpDesk.change_ask(%{"category" => "moving"}))}
  end

  @impl true
  def handle_event("validate", %{"question" => params}, socket) do
    changeset = params |> HelpDesk.change_ask() |> Map.put(:action, :validate)
    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"question" => params}, socket) do
    case HelpDesk.ask_question(params) do
      {:ok, _question} ->
        {:noreply,
         socket
         |> assign(:submitted, true)
         |> assign_form(HelpDesk.change_ask(%{"category" => "moving"}))}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  def handle_event("ask_another", _, socket), do: {:noreply, assign(socket, :submitted, false)}

  defp assign_form(socket, changeset), do: assign(socket, :form, to_form(changeset, as: :question))

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid gap-10 lg:grid-cols-5">
      <section class="lg:col-span-2">
        <h1 class="text-3xl font-bold text-zinc-900">Ask about Chennai</h1>
        <p class="mt-2 text-zinc-600">
          Rent, areas, autos, schools, weather, food, jobs, anything. We reply by email, and
          helpful answers may be shared on this page without your name or email.
        </p>

        <div :if={@submitted} class="mt-6 rounded-2xl bg-emerald-50 border border-emerald-200 p-6">
          <p class="font-semibold text-emerald-900">Nandri! Your question has been sent.</p>
          <p class="mt-1 text-emerald-800">We will email you the answer. Need help faster?</p>
          <div class="mt-4 flex gap-3">
            <.link navigate={~p"/chat"} class="rounded-full bg-brand px-4 py-2 text-white font-semibold">
              Start a live chat
            </.link>
            <button phx-click="ask_another" class="rounded-full bg-white px-4 py-2 border font-semibold">
              Ask another
            </button>
          </div>
        </div>

        <div :if={!@submitted} class="mt-2 rounded-2xl bg-white p-6 border border-zinc-200">
          <.simple_form for={@form} id="ask-form" phx-change="validate" phx-submit="save">
            <.input field={@form[:name]} type="text" label="Your name" required />
            <.input field={@form[:email]} type="email" label="Your email" required />
            <.input field={@form[:category]} type="select" label="Topic" options={@category_options} />
            <.input
              field={@form[:body]}
              type="textarea"
              label="Your question"
              placeholder="e.g. Which area is good for a family working in OMR, budget Rs 25,000?"
              required
            />
            <:actions>
              <.button phx-disable-with="Sending..." class="w-full">Send question</.button>
            </:actions>
          </.simple_form>
        </div>
      </section>

      <section class="lg:col-span-3">
        <h2 class="text-2xl font-bold text-zinc-900">Answered questions</h2>
        <p :if={@answers == []} class="mt-4 text-zinc-500">Answers will appear here.</p>
        <div :for={q <- @answers} class="mt-4 rounded-2xl bg-white p-5 border border-zinc-200">
          <p class="text-xs text-zinc-500">
            {category_icon(q.category)} {category_label(q.category)}
          </p>
          <p class="mt-1 font-semibold text-zinc-900">Q: {q.body}</p>
          <p class="mt-3 whitespace-pre-line text-zinc-700">{q.answer}</p>
        </div>
      </section>
    </div>
    """
  end
end
