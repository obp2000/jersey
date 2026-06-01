defmodule Jersey.Repo.Migrations.AddPostCostToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :post_cost, :integer
    end
  end
end
