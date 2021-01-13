class AddShopifyVariantQuantityToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :shopify_inventory, :integer
  end
end
