class Product < ApplicationRecord

  require 'roo'
  include PgSearch::Model
  pg_search_scope :search_by_shopify_ids, against: [:variant_id, :shopify_product_id, :inventory, :model_number],using: {
                    tsearch: { prefix: true }
                  }

  require 'barby/barcode/code_128'
  require 'barby/outputter/ascii_outputter'
  require 'barby/outputter/png_outputter'
  require 'barby/outputter/svg_outputter'

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
          if model_number.present? 
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
            sheet.add_row [model_number, model, color, size, product.inventory, product.price, 'ON'], types: [:string, :string, :string, :string, :string, :float, :string]
          end    
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
      # model_number = row_data[0].to_s.sub(/\.?0+$/, '')
      model_number = row_data[0].to_s
      price = row_data[5].to_s.split(' ')[0].to_f
      product = Product.find_by(model_number: model_number)
      if product.present? && row_data[6].downcase == 'on'
        product.update(inventory: row_data[4].to_i, price: price)
        update_variant_price(product.variant_id, product.inventory, product.price)
      elsif product.present? && row_data[6].downcase == 'off'
        product.delete
      elsif !product.present? && row_data[6].downcase == 'on'
        new_product = Product.new(model_number: model_number, inventory: row_data[4].to_i, price: price)
        code = "000-" + new_product.id.to_s
        barcode = Barby::Code128.new(code).to_svg(margin: 0)
        barcode = barcode.sub!('<svg ', '<svg preserveAspectRatio="none" ')
        new_product.barcode = barcode
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

  def update_variant_price(variant_id, qty, price)
    @result = HTTParty.put("https://noor-moden.myshopify.com/admin/api/2019-07/variants/#{variant_id}.json",
      :body => { 
                "variant": {:id=> variant_id, 
                  :inventory_quantity=> qty,
                  :price => price
                }
             },
      :headers => {
        'X-Shopify-Access-Token' => ENV['Access_Token']})
    end

end
