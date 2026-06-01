defmodule Jersey.CustomersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Jersey.Customers` context.
  """

  @doc """
  Generate a customer.
  """
  def customer_fixture(attrs \\ %{}) do
    {:ok, customer} =
      attrs
      |> Enum.into(%{
        name: "some name",
        nick: "some nick"
      })
      |> Jersey.Customers.create_customer()

    customer
  end

  @doc """
  Generate a city.
  """
  def city_fixture(attrs \\ %{}) do
    {:ok, city} =
      attrs
      |> Enum.into(%{
        name: "some name",
        pindex: "123456"
      })
      |> Jersey.Customers.create_city()

    city
  end
end
