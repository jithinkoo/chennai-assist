defmodule ChennaiAssist.FakeTelegram do
  @moduledoc """
  Minimal stand-in for api.telegram.org used in tests. Every call is sent to
  the process registered as `:telegram_test` as `{:telegram, token, method, params}`.
  """
  use Plug.Router

  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  post "/bot:token/:method" do
    if pid = Process.whereis(:telegram_test), do: send(pid, {:telegram, token, method, conn.body_params})

    result =
      case method do
        "getUpdates" ->
          [
            %{"message" => %{"chat" => %{"type" => "group", "id" => -5}}},
            %{"message" => %{"chat" => %{"type" => "private", "id" => 4242, "first_name" => "Jithin"}}}
          ]

        "sendMessage" ->
          %{"message_id" => 1}

        _ ->
          true
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{"ok" => true, "result" => result}))
  end

  @doc """
  Starts the fake server under the test supervisor and points the app at it.
  Call from a test `setup`; returns :ok.
  """
  def setup_fake(start_supervised) do
    Process.register(self(), :telegram_test)
    port = 40_000 + :rand.uniform(9_000)
    start_supervised.({Bandit, plug: __MODULE__, port: port, ip: {127, 0, 0, 1}, startup_log: false})

    Application.put_env(:chennai_assist, :telegram_api, "http://127.0.0.1:#{port}")
    Application.put_env(:chennai_assist, :telegram_bot_token, "TEST-TOKEN")

    ExUnit.Callbacks.on_exit(fn ->
      Application.delete_env(:chennai_assist, :telegram_api)
      Application.delete_env(:chennai_assist, :telegram_bot_token)
      Application.delete_env(:chennai_assist, :telegram_chat_id)
    end)

    :ok
  end
end
