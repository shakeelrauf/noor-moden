class RemoveInvoiceTypeToLineitems < ActiveRecord::Migration[5.2]
  def change
    remove_column :lineitems , :invoice_type
    add_column :lineitems , :standard_modiprofi_sold_quantity , :integer
  end
end
