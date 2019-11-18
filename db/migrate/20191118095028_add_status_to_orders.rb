class AddStatusToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :status, :string, default: "Processed"
  end
end
