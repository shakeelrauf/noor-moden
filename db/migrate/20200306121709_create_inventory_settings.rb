class CreateInventorySettings < ActiveRecord::Migration[5.2]
  def change
    create_table :inventory_settings do |t|
      t.boolean :is_syncing, default: true

      t.timestamps
    end
  end
end
