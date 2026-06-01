defmodule Jersey.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :customer_id, references(:customers, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:orders, [:customer_id])
  end
end
