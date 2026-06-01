defmodule Jersey.Repo.Migrations.AddAddressToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :address, :string
    end
  end
end
