class AddPaidtypeToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :paidtype , :string
  end
end
