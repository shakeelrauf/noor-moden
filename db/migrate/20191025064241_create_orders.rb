class CreateOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :orders do |t|
      t.integer :variant_id
      t.integer :product_id
      t.integer :order_qty
      t.integer :remain_qty
      t.decimal :total, precision: 8, scale: 2

      t.timestamps
    end
  end
end
