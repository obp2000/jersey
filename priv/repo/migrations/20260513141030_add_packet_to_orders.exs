defmodule Jersey.Repo.Migrations.AddPacketToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :packet, :integer
    end
  end
end
