defmodule Jersey.CustomersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Jersey.Customers` context.
  """

  alias Jersey.Customers

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
      |> Customers.create_customer()

    customer
  end

  @doc """
  Generate a city.
  """
  def city_fixture(attrs \\ %{}) do
    {:ok, city} =
      attrs
      |> Enum.into(%{
        name: "Saratov",
        pindex: "123456"
      })
      |> Customers.create_city()

    city
  end
end
