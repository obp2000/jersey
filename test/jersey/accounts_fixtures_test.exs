defmodule Jersey.AccountsFixturesTest do
  use Jersey.DataCase
  import Jersey.AccountsFixtures
  alias Jersey.Accounts.User

  describe "user_scope_fixture/0" do
    test "creates a user and returns its scope" do
      scope = user_scope_fixture()

      assert scope.user != nil
      assert %User{} = scope.user
    end
  end

  describe "user_scope_fixture/1" do
    test "returns scope for given user" do
      user = user_fixture()
      scope = user_scope_fixture(user)

      assert scope.user == user
    end
  end
end
