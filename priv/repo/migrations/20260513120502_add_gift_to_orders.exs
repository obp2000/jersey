defmodule Jersey.Repo.Migrations.AddGiftToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :gift, :string
    end
  end
end
