defmodule Jersey.Repo.Migrations.AddAddressToCustomers do
  use Ecto.Migration

  def change do
    alter table(:customers) do
      add :address, :string
    end
  end
end
