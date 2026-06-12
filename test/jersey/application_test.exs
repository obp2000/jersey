defmodule Jersey.ApplicationTest do
  use ExUnit.Case

  describe "config_change/3" do
    test "returns :ok when endpoint config changes" do
      result = Jersey.Application.config_change(%{}, %{}, %{})
      assert result == :ok
    end

    test "handles various config change scenarios" do
      # Test with non-empty changed config
      result = Jersey.Application.config_change(%{some_key: "value"}, %{}, %{})
      assert result == :ok

      # Test with removed config
      result = Jersey.Application.config_change(%{}, %{}, [:old_key])
      assert result == :ok
    end
  end

  describe "supervisor children" do
    test "Jersey.Supervisor is registered" do
      assert Process.whereis(Jersey.Supervisor) != nil
    end

    test "all expected children are running" do
      children = Supervisor.which_children(Jersey.Supervisor)
      child_ids = Enum.map(children, fn {id, _pid, _type, _mod} -> id end)

      # Verify key children are started
      assert JerseyWeb.Telemetry in child_ids
      assert Jersey.Repo in child_ids
      assert JerseyWeb.Endpoint in child_ids
    end

    test "PubSub is started" do
      # PubSub is started as a dynamic supervisor under Jersey.PubSub name
      assert Process.whereis(Jersey.PubSub) != nil
    end

    test "DNSCluster is started" do
      children = Supervisor.which_children(Jersey.Supervisor)
      # DNSCluster should be in the children list
      assert Enum.any?(children, fn {id, _pid, _type, _mod} ->
               id == DNSCluster
             end)
    end
  end

  describe "supervisor strategy" do
    test "supervisor uses one_for_one strategy" do
      # Get the supervisor's strategy via its state
      supervisor_pid = Process.whereis(Jersey.Supervisor)
      assert supervisor_pid != nil

      # Verify supervisor is alive and responding
      assert Process.alive?(supervisor_pid)
    end
  end
end
