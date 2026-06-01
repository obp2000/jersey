defmodule Jersey.Repo.Migrations.CreateCities do
  use Ecto.Migration

  def change do
    create table(:cities) do
      add :pindex, :string, size: 6
      add :name, :string, size: 80

      timestamps(type: :utc_datetime)
    end
  end
end
