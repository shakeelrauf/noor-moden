class AddVariantIdToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :variant_id, :integer
  end
end
