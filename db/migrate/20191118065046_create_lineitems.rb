class CreateLineitems < ActiveRecord::Migration[5.2]
  def change
    create_table :lineitems do |t|
      t.references :order, foreign_key: true
      t.integer :shopify_product_id, limit: 8
      t.integer :variant_id, limit: 8
      t.integer :order_qty
      t.integer :remain_qty
      t.decimal :total, precision: 8, scale: 2
      t.decimal :price, precision: 8, scale: 2
      t.integer :product_id
      t.string :sku

      t.timestamps
    end
  end
end
