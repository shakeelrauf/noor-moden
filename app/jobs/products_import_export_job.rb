class ProductsImportExportJob < ApplicationJob
  queue_as :default

  def perform(type, file_id = nil)
    if type == 'export'
      Product.all.export()
    else
      spreadsheet = Spreadsheet.find(file_id)
      file_path = ActiveStorage::Blob.service.send(:path_for, spreadsheet.file.key)
      Product.import(file_path, file_id)
    end
  end
end
