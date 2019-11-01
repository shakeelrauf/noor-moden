class AddModelNumberToProducts < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :model_number, :string
  end
end
