class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!, only: [:update_shopify_product, :create_product, :delete_product, :notify_new_customer_shopify_admin, :notify_update_customer_shopify_admin]

  require 'barby/barcode/code_128'
  require 'barby/outputter/ascii_outputter'
  require 'barby/outputter/png_outputter'
  require 'barby/outputter/svg_outputter'
  include ApiCalls
  include CsvExporter
  # GET /products
  # GET /products.json
  def index
    if SkuType.all.count < 1
      SkuType.create(sku_type: "Restware")
    end
    
    @syncing_status = InventorySetting.last.is_syncing
    @sku_type = SkuType&.last&.sku_type
    if params[:query].present?
      @products = Product.search_by_shopify_ids(params[:query]).paginate(page: params[:page], per_page: 10)
    else
      if params[:sort_by] == 'skuAsc'
        @products = Product.order('model_number').paginate(page: params[:page], per_page: 10)
      elsif params[:sort_by] == 'skuDesc'
        @products = Product.order('model_number DESC').paginate(page: params[:page], per_page: 10)
      elsif params[:sort_by] == 'dateAsc'
        @products = Product.order('updated_at').paginate(page: params[:page], per_page: 10)
      else
        @products = Product.order('updated_at DESC').paginate(page: params[:page], per_page: 10)
      end
    end
  end

  def change_sync
    if params[:is_syncing]
      syncing = InventorySetting.last
      syncing.is_syncing = !InventorySetting.last.is_syncing
      syncing.save
    end
  end

  def change_sku_type
    if params[:sku_type]  
      type = SkuType.last
      if type.present?
        type.sku_type = params[:sku_type]
        type.save
      end
    end
  end

  def suggestions
    @products = Product.search_by_shopify_ids(params[:term])
    render json: @products.map(&:model_number).uniq 
  end

  def modelnumbers
    @products = Product.search_by_sku(params[:term])
    render json: @products.map(&:model_number).uniq
  end

  # GET /products/1
  # GET /products/1.json
  def show
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
  end

  # POST /products
  # POST /products.json
  def create
    @product = Product.new(product_params)
    respond_to do |format|
      if @product.save
        code = "000-" + @product.id.to_s
        barcode = Barby::Code128.new(code).to_svg(margin: 0)
        barcode = barcode.sub!('<svg ', '<svg preserveAspectRatio="none" ')
        @product.barcode = barcode
        @product.save
        format.html { redirect_to @product, notice: 'Product was successfully created.' }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    respond_to do |format|
      if @product.update(product_params)
        if @product.variant_id.present?
          update_variant_price(@product.variant_id, @product.inventory, @product.price)
        end
        format.html { redirect_to @product, notice: 'Product was successfully updated.' }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  def update_sync_with_modeprofi
    @product = Product.find_by_id(params[:product_id])
    modeprofi = params[:sync_with_modeprofi].nil? ?  false : true
    @product.update(sync_with_modeprofi: modeprofi)
    respond_to do |format|
      format.js { render :updated_sync_with_modeprofi }
    end  
  end

  def export
    ProductsImportExportJob.perform_later('export');
    redirect_to products_path, notice: "Exporting Products..."
  end

  def import
    spreadsheet = Spreadsheet.new(file_type: 'import')
    spreadsheet.file.attach(params[:file])
    spreadsheet.save
    ProductsImportExportJob.perform_later('import', spreadsheet.id);
    redirect_to products_path, notice: "Importing Products..."
  end

  def update_shopify_product
    if InventorySetting.last.is_syncing == true
      in_house_variants = Product.where(shopify_product_id: params[:id]).collect { |c| c.variant_id }
      shopify_variant_ids = params[:variants].collect { |c| c["id"] }
      deleted_variant_ids = in_house_variants - shopify_variant_ids
      if deleted_variant_ids.present?
        Product.where(variant_id: deleted_variant_ids).destroy_all
      end
      sync_shopify_data
    end

  end

  def create_product
    if InventorySetting.last.is_syncing == true
      sync_shopify_data
    end
  end

  def delete_product
    # if InventorySetting.last.is_syncing == true
      Product.where(shopify_product_id: params[:id]).destroy_all
    # end
  end

  def notify_new_customer_shopify_admin
    country = params[:note].split("\n").select{ |e| e.include? 'country' }.first&.split(":")&.last&.strip
    accept_marketing = params[:note].split("\n").select{ |e| e.include? 'register_newsletter' }.first&.split(":")&.last&.strip == "true"
    update_customer(params[:id],country,accept_marketing)
    CustomerMailer.send_shopify_signup_notification(params).deliver_now
  end

  def notify_update_customer_shopify_admin
    country = params[:note].split("\n").select{ |e| e.include? 'country' }.first&.split(":")&.last&.strip
    update_customer(params[:id],country,params["accepts_marketing"])
    head 200
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    @product.destroy
    if @product.shopify_product_id.present?
      delete_variant(@product.shopify_product_id, @product.variant_id)
    end
    respond_to do |format|
      format.html { redirect_to products_url, notice: 'Product was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def get_barcode
    @product = Product.where(id: params[:barcode].split("-")[1]).first
    if @product.present?
      render json: { data: @product.as_json, status: 200 }
    else
      render json: { data: [], status: 404 }
    end
  end

  def get_barcode_from_sku
    @product = Product.where(model_number: params[:barcode]).first
    if @product.present?
      render json: { data: @product.as_json, status: 200 }
    else
      render json: { data: [], status: 404 }
    end
  end

  def create_order
    # Match against session token to prevent double order entry
    if session[:create_order_random_token] == params[:random_token]
      session.delete(:create_order_random_token)
      returned_data = SaleOrderHandler.new(params).generate_order
      if returned_data.present?
        export_order_to_csv(returned_data)
      end
    end
    redirect_to products_path, notice: 'Your Inventory Has been updated.'
  end

  def start_scanning
    @sku_type = SkuType&.last&.sku_type
    session[:create_order_random_token] = SecureRandom.hex
  end

  private

    # Use callbacks to share common setup or constraints between actions.
    def sync_shopify_data
      params[:variants].each do |variant|
        product_present = Product.where(model_number: variant['sku']).where.not(model_number: "").first
        if !product_present.present?
          if variant['sku'].present?
            product = Product.create(shopify_product_id: variant['product_id'], 
              variant_id: variant['id'],
              inventory: variant['inventory_quantity'],
              # price: variant['price'],
              model_number: variant['sku']
            )
            code = "000-" + product.id.to_s
            barcode = Barby::Code128.new(code).to_svg(margin: 0)
            barcode = barcode.sub!('<svg ', '<svg preserveAspectRatio="none" ')
            product.barcode = barcode
            product.save
          end
        else
          puts "PRODUCT PRESENT"
          if InventorySetting.last.is_syncing == false
            puts "SYNCING FALSE"
            puts "PRODUCT DETAILS ********#{product_present.as_json}"
            if product_present.inventory.to_s != variant['inventory_quantity'].to_s
              update_inventory(variant['id'], product_present.inventory)
              sleep 2
            end
            product_present.variant_id = variant['id']
            product_present.shopify_product_id = variant['product_id']
            product_present.model_number = variant['sku']
            product_present.save
          else
            product_present.variant_id = variant['id']
            product_present.shopify_product_id = variant['product_id']
            # product_present.price = variant['price']
            product_present.inventory = variant['inventory_quantity']
            product_present.model_number = variant['sku']
            product_present.save
          end
        end
      end
    end

    def set_product
      @product = Product.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def product_params
      params.require(:product).permit(:shopify_product_id, :inventory,:modeprofi_inventory, :barcode, :price, :variant_id, :model_number, :sync_with_modeprofi)
    end
end
