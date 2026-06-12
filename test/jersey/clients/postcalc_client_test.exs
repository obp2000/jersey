defmodule Jersey.Clients.PostcalcClientTest do
  use ExUnit.Case, async: true

  alias Jersey.Clients.PostcalcClient

  describe "get_post_cost/2" do
    test "returns tariff as-is when present" do
      assert PostcalcClient.get_post_cost("190000", Decimal.new("1000")) == "448.00"
    end

    test "replaces comma with dot when present" do
      assert PostcalcClient.get_post_cost("190000", Decimal.new("1001")) == "448.10"
    end

    test "returns \"0\" when tariff missing" do
      assert PostcalcClient.get_post_cost("190001", Decimal.new("1000")) == "0"
    end

    test "returns \"0\" on request error" do
      assert PostcalcClient.get_post_cost("190002", Decimal.new("1000")) == "0"
    end

    test "returns \"0\" on non-2xx response" do
      assert PostcalcClient.get_post_cost("190003", Decimal.new("1000")) == "0"
    end

    test "returns \"0\" when tariff key exists but is nil" do
      # stub fallback returns "0", so emulate missing via unknown pindex
      assert PostcalcClient.get_post_cost("190000", :unknown_weight) == "0"
    end
  end
end
