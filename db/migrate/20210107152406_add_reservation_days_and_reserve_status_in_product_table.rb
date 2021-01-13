class AddReservationDaysAndReserveStatusInProductTable < ActiveRecord::Migration[5.2]
  def change
    add_column :products, :reservation_days, :integer
    add_column :products, :reserve_status, :boolean, default: false
  end
end
