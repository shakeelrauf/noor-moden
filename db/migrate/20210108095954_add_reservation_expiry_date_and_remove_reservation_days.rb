class AddReservationExpiryDateAndRemoveReservationDays < ActiveRecord::Migration[5.2]
  def change
    remove_column :orders, :reservation_days
    add_column :orders, :reservation_expiry_date, :date
  end
end
