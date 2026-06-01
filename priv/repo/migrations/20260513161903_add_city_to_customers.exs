defmodule Jersey.Repo.Migrations.AddCityToCustomers do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      add :city_id, references(:cities, on_delete: :restrict)
    end

    create index(:customers, [:city_id])
  end
end
