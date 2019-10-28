class ChangeIntegerLimitInYourProduct < ActiveRecord::Migration[5.2]
  def change
  	change_column :products, :shopify_product_id, :integer, limit: 8
  	change_column :products, :variant_id, :integer, limit: 8
  end
end
