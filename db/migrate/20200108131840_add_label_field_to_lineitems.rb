class AddLabelFieldToLineitems < ActiveRecord::Migration[5.2]
  def change
    add_column :lineitems, :label, :text
  end
end
