class CreateSpreadsheets < ActiveRecord::Migration[5.2]
  def change
    create_table :spreadsheets do |t|
      t.string :file_type

      t.timestamps
    end
  end
end
