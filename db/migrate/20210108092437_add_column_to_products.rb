class AddColumnToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :sync_with_modiprofi, :boolean, default: true
  end
end
