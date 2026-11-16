defmodule ChennaiAssistWeb.Admin.InterviewLiveTest do
  use ChennaiAssistWeb.ConnCase

  import Phoenix.LiveViewTest
  import ChennaiAssist.ContentFixtures

  @create_attrs %{area: "some area", body: "some body", occupation: "some occupation", person_name: "some person_name", photo_url: "some photo_url", published: true, slug: "some-slug", title: "some title"}
  @update_attrs %{area: "some updated area", body: "some updated body", occupation: "some updated occupation", person_name: "some updated person_name", photo_url: "some updated photo_url", published: false, slug: "some-updated-slug", title: "some updated title"}
  @invalid_attrs %{area: nil, body: nil, occupation: nil, person_name: nil, photo_url: nil, published: false, slug: nil, title: nil}

  defp create_interview(_) do
    interview = interview_fixture()
    %{interview: interview}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_interview]

    test "lists all interviews", %{conn: conn, interview: interview} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/interviews")

      assert html =~ "Listing Interviews"
      assert html =~ interview.area
    end

    test "saves new interview", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/interviews")

      assert index_live |> element("a", "New Interview") |> render_click() =~
               "New Interview"

      assert_patch(index_live, ~p"/admin/interviews/new")

      assert index_live
             |> form("#interview-form", interview: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#interview-form", interview: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/interviews")

      html = render(index_live)
      assert html =~ "Interview created successfully"
      assert html =~ "some area"
    end

    test "updates interview in listing", %{conn: conn, interview: interview} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/interviews")

      assert index_live |> element("#interviews-#{interview.id} a", "Edit") |> render_click() =~
               "Edit Interview"

      assert_patch(index_live, ~p"/admin/interviews/#{interview}/edit")

      assert index_live
             |> form("#interview-form", interview: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#interview-form", interview: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/interviews")

      html = render(index_live)
      assert html =~ "Interview updated successfully"
      assert html =~ "some updated area"
    end

    test "deletes interview in listing", %{conn: conn, interview: interview} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/interviews")

      assert index_live |> element("#interviews-#{interview.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#interviews-#{interview.id}")
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :create_interview]

    test "displays interview", %{conn: conn, interview: interview} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/interviews/#{interview}")

      assert html =~ "Show Interview"
      assert html =~ interview.area
    end

    test "updates interview within modal", %{conn: conn, interview: interview} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/interviews/#{interview}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Interview"

      assert_patch(show_live, ~p"/admin/interviews/#{interview}/show/edit")

      assert show_live
             |> form("#interview-form", interview: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#interview-form", interview: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/interviews/#{interview}")

      html = render(show_live)
      assert html =~ "Interview updated successfully"
      assert html =~ "some updated area"
    end
  end
end
