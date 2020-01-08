class AddLabelFieldToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :label, :text
  end
end
