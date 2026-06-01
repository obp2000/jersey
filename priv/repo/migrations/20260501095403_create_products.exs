defmodule Jersey.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string, null: false
      add :price, :integer, default: 0, null: false
      add :weight, :decimal
      add :width, :integer
      add :density, :integer
      add :dollar_price, :decimal
      add :dollar_rate, :decimal
      add :width_shop, :integer
      add :density_shop, :integer
      add :weight_for_count, :integer
      add :length_for_count, :decimal, default: 1.0
      add :price_pre, :integer
      add :image, :string

      timestamps(type: :utc_datetime)
    end
  end
end
