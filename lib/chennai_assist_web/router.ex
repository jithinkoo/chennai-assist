defmodule ChennaiAssistWeb.Router do
  use ChennaiAssistWeb, :router

  import ChennaiAssistWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ChennaiAssistWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  ## Telegram replies from the admin (see TelegramWebhookController)

  scope "/telegram", ChennaiAssistWeb do
    pipe_through :api
    post "/webhook", TelegramWebhookController, :create
  end

  ## Public site

  scope "/", ChennaiAssistWeb.Site do
    pipe_through :browser

    live_session :public, on_mount: [{ChennaiAssistWeb.UserAuth, :mount_current_user}] do
      live "/", HomeLive, :index
      live "/guide", GuideLive, :index
      live "/guide/:slug", GuideLive, :show
      live "/ask", AskLive, :index
      live "/photos", PhotosLive, :index
      live "/interviews", InterviewsLive, :index
      live "/interviews/:slug", InterviewsLive, :show
      live "/chat", ChatLive, :start
      live "/chat/:token", ChatLive, :chat
    end
  end

  ## Admin (only logged-in users; public registration is disabled)

  scope "/admin", ChennaiAssistWeb.Admin, as: :admin do
    pipe_through [:browser, :require_authenticated_user]

    live_session :admin,
      on_mount: [
        {ChennaiAssistWeb.UserAuth, :ensure_authenticated},
        ChennaiAssistWeb.Admin.AlertsHook
      ] do
      live "/", DashboardLive, :index
      live "/notifications", NotificationsLive, :index
      live "/chats", ChatsLive, :index
      live "/chats/:id", ChatsLive, :show
      live "/questions", QuestionsLive, :index
      live "/photos", PhotosLive, :index

      live "/guides", GuideLive.Index, :index
      live "/guides/new", GuideLive.Index, :new
      live "/guides/:id/edit", GuideLive.Index, :edit
      live "/guides/:id", GuideLive.Show, :show
      live "/guides/:id/show/edit", GuideLive.Show, :edit

      live "/interviews", InterviewLive.Index, :index
      live "/interviews/new", InterviewLive.Index, :new
      live "/interviews/:id/edit", InterviewLive.Index, :edit
      live "/interviews/:id", InterviewLive.Show, :show
      live "/interviews/:id/show/edit", InterviewLive.Show, :edit
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:chennai_assist, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ChennaiAssistWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes (admin login only)

  scope "/", ChennaiAssistWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ChennaiAssistWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", ChennaiAssistWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ChennaiAssistWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", ChennaiAssistWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{ChennaiAssistWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
