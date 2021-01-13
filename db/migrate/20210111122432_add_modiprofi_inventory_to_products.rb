class AddModiprofiInventoryToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :modeprofi_inventory, :integer
    rename_column :products, :sync_with_modiprofi, :sync_with_modeprofi
  end
end
