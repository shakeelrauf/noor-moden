class RemoveReservationDaysAndReserveStatusFromProductTable < ActiveRecord::Migration[5.2]
  def change
    remove_column :products, :reservation_days
    remove_column :products, :reserve_status
  end
end
