class AddNoteInOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :note,:string
  end
end
