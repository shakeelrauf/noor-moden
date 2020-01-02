class Product < ApplicationRecord
  require 'roo'
  include PgSearch::Model
  pg_search_scope :search_by_shopify_ids, against: [:variant_id, :shopify_product_id, :inventory, :model_number],using: {
                    tsearch: { prefix: true }
                  }


  def self.to_csv
    attributes = ['SKU', 'Model', 'Color', 'Size', 'Quantity', 'Price', 'Status']
    CSV.generate(headers: true) do |csv|
      csv << attributes
      all.each do |product|
        model_number = product.model_number
        if model_number.include? ('/')
        else
          length = model_number.length
          size = model_number[length-2..length-1]
          color = model_number[length-4..length-3]
          model = model_number[0..length-5]
        end
        csv << [model_number, model, color, size, product.inventory, product.price, 'ON']
      end
    end
  end

  def self.export
    p = Axlsx::Package.new
    p.workbook do |wb|
      wb.add_worksheet(name: 'Products') do |sheet|
        sheet.add_row %w(SKU Model Color Size Quantity Price Status)
        all.each do |product|
          model_number = product.model_number
          if model_number.include? ('/')
              length = model_number.length
              size = model_number[length-2..length-1]
              color = model_number[length-7..length-3]
              model = model_number[0..length-8]
          else
              length = model_number.length
              size = model_number[length-2..length-1]
              color = model_number[length-4..length-3]
              model = model_number[0..length-5]
          end
          sheet.add_row [model_number, model, color, size, product.inventory, product.price, 'ON']    
        end 
      end
    end
    p.serialize("#{Rails.root}/Products.xlsx") 
    outstrio = StringIO.new
    p.use_shared_strings = true 
    outstrio.write(p.to_stream.read)
    file = outstrio.string
    CustomerMailer.products_exported(file).deliver_now
  end

  def self.import(file_path, spreadsheet_id)
    spreadsheet = Roo::Spreadsheet.open(file_path, extension: :xlsx)
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      row_data = spreadsheet.row(i)
      product = Product.find_by(model_number: row_data[0].to_i)
      if product.present? && row_data[6].downcase == 'on'
        product.update(inventory: row_data[4].to_i, price: row_data[5].to_i)
      elsif row_data[6].downcase == 'off'
        product.delete
      else
        new_product = Product.new(model_number: row_data[0], inventory: row_data[4].to_i, price: row_data[5].to_i)
        new_product.save!
      end
    end
    Spreadsheet.find(spreadsheet_id).delete
    CustomerMailer.products_imported(file_path).deliver_now
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".xlsx" then Roo::Spreadsheet.open(file.path, extension: :xlsx)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end
end
