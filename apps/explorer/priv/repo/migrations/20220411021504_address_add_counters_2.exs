defmodule Explorer.Repo.Migrations.AddressAddCounters2 do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      add(:incoming_transactions_count, :integer, null: true)
      add(:token_incoming_transfers_count, :integer, null: true)
    end
  end
end
