class ChangeIntegerLimitInOrders < ActiveRecord::Migration[5.2]
  def change
  	change_column :orders, :variant_id, :integer, limit: 8
  	change_column :orders, :product_id, :integer, limit: 8
  end
end
