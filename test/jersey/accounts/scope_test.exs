defmodule Jersey.Accounts.ScopeTest do
  use ExUnit.Case
  alias Jersey.Accounts.{Scope, User}

  describe "for_user/1" do
    test "returns scope with user for valid user" do
      user = %User{email: "test@example.com", hashed_password: "secret"}
      scope = Scope.for_user(user)

      assert scope.user == user
    end

    test "returns nil for nil user" do
      assert Scope.for_user(nil) == nil
    end
  end

  describe "%Scope{} default" do
    test "sets user to nil by default" do
      scope = %Scope{}
      assert scope.user == nil
    end
  end
end
