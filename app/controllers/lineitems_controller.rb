class LineitemsController < ApplicationController
  before_action :set_lineitem, only: [:show, :edit, :update, :destroy]

  # GET /lineitems
  # GET /lineitems.json
  def index
    @lineitems = Lineitem.all
  end

  # GET /lineitems/1
  # GET /lineitems/1.json
  def show
  end

  # GET /lineitems/new
  def new
    @lineitem = Lineitem.new
  end

  # GET /lineitems/1/edit
  def edit
    @product = Product.find(@lineitem.product_id)
  end

  # POST /lineitems
  # POST /lineitems.json
  def create
    @lineitem = Lineitem.new(lineitem_params)

    respond_to do |format|
      if @lineitem.save
        format.html { redirect_to @lineitem, notice: 'Lineitem was successfully created.' }
        format.json { render :show, status: :created, location: @lineitem }
      else
        format.html { render :new }
        format.json { render json: @lineitem.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /lineitems/1
  # PATCH/PUT /lineitems/1.json
  def update
    product = Product.find(params[:lineitem][:product_id])
    prev_qty = @lineitem.order_qty
    cur_qty = params[:lineitem][:order_qty].to_i
    qty = prev_qty - cur_qty

    if cur_qty > prev_qty && !(qty < 0)
      final_qty = product.inventory - qty
    else
      final_qty = product.inventory + qty
    end
    respond_to do |format|
      if @lineitem.update(lineitem_params)
        @lineitem.remain_qty = final_qty
        @lineitem.save
        if product.variant_id.present?
          update_inventory(product.variant_id, final_qty)
        else
          product.inventory = final_qty
          product.save
        end
        format.html { redirect_to @lineitem, notice: 'Lineitem was successfully updated.' }
        format.json { render :show, status: :ok, location: @lineitem }
      else
        format.html { render :edit }
        format.json { render json: @lineitem.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lineitems/1
  # DELETE /lineitems/1.json
  def destroy
    @lineitem.destroy
    respond_to do |format|
      format.html { redirect_to lineitems_url, notice: 'Lineitem was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.

    def update_inventory(variant_id, qty)
      @result = HTTParty.put("#{ENV['SHOPIFY_API_URL']}/variants/#{variant_id}.json",
        :body => { 
                  "variant": {:id=> variant_id, 
                    :inventory_quantity=> qty,
                  }
               },
        :headers => {
          'X-Shopify-Access-Token' => ENV['Access_Token']})

      @result = HTTParty.put("#{ENV['SHOPIFY_API_URL2']}/variants/#{variant_id}.json",
        :body => { 
                  "variant": {:id=> variant_id, 
                    :inventory_quantity=> qty,
                  }
               },
        :headers => {
          'X-Shopify-Access-Token' => ENV['Access_Token2']})
    end

    def set_lineitem
      @lineitem = Lineitem.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def lineitem_params
      params.require(:lineitem).permit(:order_id, :product_id, :variant_id, :order_qty, :remain_qty, :total, :sku)
    end
end
