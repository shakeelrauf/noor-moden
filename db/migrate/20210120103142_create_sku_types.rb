class CreateSkuTypes < ActiveRecord::Migration[5.2]
  def change
    create_table :sku_types do |t|
      t.string :sku_type , default: "Restware"
    end
  end
end
