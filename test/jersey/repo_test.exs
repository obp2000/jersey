defmodule Jersey.RepoTest do
  use Jersey.DataCase, async: true

  alias Jersey.Accounts.User

  describe "insert/1" do
    test "inserts a valid struct successfully" do
      {:ok, user} = Repo.insert(%User{email: "new@example.com", hashed_password: "secret123"})

      assert user.id != nil
      assert user.email == "new@example.com"
    end
  end

  describe "insert!/1" do
    test "inserts a valid record and returns it" do
      user = Repo.insert!(%User{email: "bang@example.com", hashed_password: "secret123"})

      assert user.id != nil
      assert user.email == "bang@example.com"
    end
  end

  describe "get/2" do
    setup do
      {:ok, user} = Repo.insert(%User{email: "get@example.com", hashed_password: "secret123"})
      %{user: user}
    end

    test "returns record by id", %{user: user} do
      result = Repo.get(User, user.id)
      assert result.id == user.id
      assert result.email == user.email
    end

    test "returns nil for non-existent id" do
      result = Repo.get(User, 99999)
      assert result == nil
    end
  end

  describe "get!/2" do
    setup do
      {:ok, user} = Repo.insert(%User{email: "getbang@example.com", hashed_password: "secret123"})
      %{user: user}
    end

    test "returns record by id", %{user: user} do
      result = Repo.get!(User, user.id)
      assert result.id == user.id
    end

    test "raises on non-existent id" do
      assert_raise Ecto.NoResultsError, fn ->
        Repo.get!(User, 99999)
      end
    end
  end

  describe "get_by/2" do
    setup do
      {:ok, user} = Repo.insert(%User{email: "getby@example.com", hashed_password: "secret123"})
      %{user: user}
    end

    test "returns record by field value", %{user: user} do
      result = Repo.get_by(User, email: "getby@example.com")
      assert result.id == user.id
    end

    test "returns nil when no match found" do
      result = Repo.get_by(User, email: "nonexistent@example.com")
      assert result == nil
    end
  end

  describe "get_by!/2" do
    setup do
      {:ok, user} =
        Repo.insert(%User{email: "getbybang@example.com", hashed_password: "secret123"})

      %{user: user}
    end

    test "returns record by field value", %{user: user} do
      result = Repo.get_by!(User, email: "getbybang@example.com")
      assert result.id == user.id
    end

    test "raises when no match found" do
      assert_raise Ecto.NoResultsError, fn ->
        Repo.get_by!(User, email: "nonexistent@example.com")
      end
    end
  end

  describe "all/1" do
    setup do
      {:ok, _user1} = Repo.insert(%User{email: "all1@example.com", hashed_password: "secret123"})
      {:ok, _user2} = Repo.insert(%User{email: "all2@example.com", hashed_password: "secret123"})
      :ok
    end

    test "returns all records of a schema" do
      result = Repo.all(User)
      assert length(result) == 2
    end
  end

  describe "delete/1" do
    setup do
      {:ok, user} = Repo.insert(%User{email: "delete@example.com", hashed_password: "secret123"})
      %{user: user}
    end

    test "deletes a record successfully", %{user: user} do
      {:ok, deleted_user} = Repo.delete(user)
      assert deleted_user.id == user.id
      assert Repo.get(User, user.id) == nil
    end
  end

  describe "delete!/1" do
    setup do
      {:ok, user} =
        Repo.insert(%User{email: "deletebang@example.com", hashed_password: "secret123"})

      %{user: user}
    end

    test "deletes a record and returns it", %{user: user} do
      deleted_user = Repo.delete!(user)
      assert deleted_user.id == user.id
      assert Repo.get(User, user.id) == nil
    end
  end

  describe "update/1" do
    setup do
      {:ok, user} = Repo.insert(%User{email: "update@example.com", hashed_password: "secret123"})
      %{user: user}
    end

    test "updates a record successfully", %{user: user} do
      changeset = Ecto.Changeset.change(user, email: "updated@example.com")
      {:ok, updated_user} = Repo.update(changeset)

      assert updated_user.email == "updated@example.com"
    end
  end

  describe "update!/1" do
    setup do
      {:ok, user} =
        Repo.insert(%User{email: "updatebang@example.com", hashed_password: "secret123"})

      %{user: user}
    end

    test "updates a record and returns it", %{user: user} do
      changeset = Ecto.Changeset.change(user, email: "updatedbang@example.com")
      updated_user = Repo.update!(changeset)

      assert updated_user.email == "updatedbang@example.com"
    end
  end

  describe "one/1" do
    setup do
      {:ok, user} = Repo.insert(%User{email: "one@example.com", hashed_password: "secret123"})
      %{user: user}
    end

    test "returns single record matching query", %{user: user} do
      result = Repo.one(from u in User, where: u.email == "one@example.com")
      assert result.id == user.id
    end

    test "returns nil when no match found" do
      result = Repo.one(from u in User, where: u.email == "nonexistent@example.com")
      assert result == nil
    end
  end

  describe "one!/1" do
    setup do
      {:ok, user} = Repo.insert(%User{email: "onebang@example.com", hashed_password: "secret123"})
      %{user: user}
    end

    test "returns single record matching query", %{user: user} do
      result = Repo.one!(from u in User, where: u.email == "onebang@example.com")
      assert result.id == user.id
    end

    test "raises when no match found" do
      assert_raise Ecto.NoResultsError, fn ->
        Repo.one!(from u in User, where: u.email == "nonexistent@example.com")
      end
    end
  end

  describe "transaction/2" do
    test "commits transaction on success" do
      {:ok, result} =
        Repo.transaction(fn ->
          Repo.insert!(%User{email: "tx@example.com", hashed_password: "secret123"})
        end)

      assert result.email == "tx@example.com"
    end

    test "rolls back transaction on failure" do
      initial_count = Repo.all(User) |> length()

      assert_raise RuntimeError, "rollback this", fn ->
        Repo.transaction(fn ->
          raise "rollback this"
        end)
      end

      final_count = Repo.all(User) |> length()
      assert initial_count == final_count
    end
  end

  describe "Scrivener pagination" do
    setup do
      # Create 12 users for pagination tests
      for i <- 1..12 do
        Repo.insert!(%User{email: "pag_user#{i}@example.com", hashed_password: "secret123"})
      end

      :ok
    end

    test "paginate/2 returns correct page structure" do
      result = Repo.paginate(User, page: 1, page_size: 5)

      assert result.entries |> length() == 5
      assert result.page_number == 1
      assert result.page_size == 5
      assert result.total_entries == 12
      assert result.total_pages == 3
    end

    test "paginate/2 returns second page correctly" do
      result = Repo.paginate(User, page: 2, page_size: 5)

      assert result.entries |> length() == 5
      assert result.page_number == 2
      assert result.total_entries == 12
    end

    test "paginate/2 returns last page with fewer entries" do
      result = Repo.paginate(User, page: 3, page_size: 5)

      assert result.entries |> length() == 2
      assert result.page_number == 3
    end
  end
end
