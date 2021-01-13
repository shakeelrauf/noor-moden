class RemoveShopifyVariantQuantit < ActiveRecord::Migration[5.2]
  def change
    remove_column :products, :shopify_inventory
  end
end
