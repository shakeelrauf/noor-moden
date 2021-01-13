class AddReservationDaysAndReserveStatusInOrdersTableAgain < ActiveRecord::Migration[5.2]
  def change
    remove_column :products, :reservation_days
    remove_column :products, :reserve_status
    add_column :orders, :reservation_days, :integer
    add_column :orders, :reserve_status, :boolean, default: false
  end
end
