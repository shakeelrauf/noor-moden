class AddInvoiceTypeToLineitems < ActiveRecord::Migration[5.2]
  def change
    add_column :lineitems , :invoice_type , :string
  end
end
