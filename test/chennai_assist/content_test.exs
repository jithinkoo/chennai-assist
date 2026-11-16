defmodule ChennaiAssist.ContentTest do
  use ChennaiAssist.DataCase

  alias ChennaiAssist.Content

  describe "guides" do
    alias ChennaiAssist.Content.Guide

    import ChennaiAssist.ContentFixtures

    @invalid_attrs %{body: nil, category: nil, published: nil, slug: nil, summary: nil, title: nil}

    test "list_guides/0 returns all guides" do
      guide = guide_fixture()
      assert Content.list_guides() == [guide]
    end

    test "get_guide!/1 returns the guide with given id" do
      guide = guide_fixture()
      assert Content.get_guide!(guide.id) == guide
    end

    test "create_guide/1 with valid data creates a guide" do
      valid_attrs = %{body: "some body", category: "food", published: true, slug: "some-slug", summary: "some summary", title: "some title"}

      assert {:ok, %Guide{} = guide} = Content.create_guide(valid_attrs)
      assert guide.body == "some body"
      assert guide.category == "food"
      assert guide.published == true
      assert guide.slug == "some-slug"
      assert guide.summary == "some summary"
      assert guide.title == "some title"
    end

    test "create_guide/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Content.create_guide(@invalid_attrs)
    end

    test "update_guide/2 with valid data updates the guide" do
      guide = guide_fixture()
      update_attrs = %{body: "some updated body", category: "rent", published: false, slug: "some-updated-slug", summary: "some updated summary", title: "some updated title"}

      assert {:ok, %Guide{} = guide} = Content.update_guide(guide, update_attrs)
      assert guide.body == "some updated body"
      assert guide.category == "rent"
      assert guide.published == false
      assert guide.slug == "some-updated-slug"
      assert guide.summary == "some updated summary"
      assert guide.title == "some updated title"
    end

    test "update_guide/2 with invalid data returns error changeset" do
      guide = guide_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.update_guide(guide, @invalid_attrs)
      assert guide == Content.get_guide!(guide.id)
    end

    test "delete_guide/1 deletes the guide" do
      guide = guide_fixture()
      assert {:ok, %Guide{}} = Content.delete_guide(guide)
      assert_raise Ecto.NoResultsError, fn -> Content.get_guide!(guide.id) end
    end

    test "change_guide/1 returns a guide changeset" do
      guide = guide_fixture()
      assert %Ecto.Changeset{} = Content.change_guide(guide)
    end
  end

  describe "interviews" do
    alias ChennaiAssist.Content.Interview

    import ChennaiAssist.ContentFixtures

    @invalid_attrs %{area: nil, body: nil, occupation: nil, person_name: nil, photo_url: nil, published: nil, slug: nil, title: nil}

    test "list_interviews/0 returns all interviews" do
      interview = interview_fixture()
      assert Content.list_interviews() == [interview]
    end

    test "get_interview!/1 returns the interview with given id" do
      interview = interview_fixture()
      assert Content.get_interview!(interview.id) == interview
    end

    test "create_interview/1 with valid data creates a interview" do
      valid_attrs = %{area: "some area", body: "some body", occupation: "some occupation", person_name: "some person_name", photo_url: "some photo_url", published: true, slug: "some-slug", title: "some title"}

      assert {:ok, %Interview{} = interview} = Content.create_interview(valid_attrs)
      assert interview.area == "some area"
      assert interview.body == "some body"
      assert interview.occupation == "some occupation"
      assert interview.person_name == "some person_name"
      assert interview.photo_url == "some photo_url"
      assert interview.published == true
      assert interview.slug == "some-slug"
      assert interview.title == "some title"
    end

    test "create_interview/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Content.create_interview(@invalid_attrs)
    end

    test "update_interview/2 with valid data updates the interview" do
      interview = interview_fixture()
      update_attrs = %{area: "some updated area", body: "some updated body", occupation: "some updated occupation", person_name: "some updated person_name", photo_url: "some updated photo_url", published: false, slug: "some-updated-slug", title: "some updated title"}

      assert {:ok, %Interview{} = interview} = Content.update_interview(interview, update_attrs)
      assert interview.area == "some updated area"
      assert interview.body == "some updated body"
      assert interview.occupation == "some updated occupation"
      assert interview.person_name == "some updated person_name"
      assert interview.photo_url == "some updated photo_url"
      assert interview.published == false
      assert interview.slug == "some-updated-slug"
      assert interview.title == "some updated title"
    end

    test "update_interview/2 with invalid data returns error changeset" do
      interview = interview_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.update_interview(interview, @invalid_attrs)
      assert interview == Content.get_interview!(interview.id)
    end

    test "delete_interview/1 deletes the interview" do
      interview = interview_fixture()
      assert {:ok, %Interview{}} = Content.delete_interview(interview)
      assert_raise Ecto.NoResultsError, fn -> Content.get_interview!(interview.id) end
    end

    test "change_interview/1 returns a interview changeset" do
      interview = interview_fixture()
      assert %Ecto.Changeset{} = Content.change_interview(interview)
    end
  end
end
