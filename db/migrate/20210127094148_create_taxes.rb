class CreateTaxes < ActiveRecord::Migration[5.2]
  def change
    create_table :taxes do |t|
      t.float :percentage, default: 0
      t.timestamps
    end
  end
end
