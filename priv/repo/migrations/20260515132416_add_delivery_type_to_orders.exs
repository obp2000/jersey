defmodule Jersey.Repo.Migrations.AddDeliveryTypeToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :delivery_type, :integer
    end
  end
end
