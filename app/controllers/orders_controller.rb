class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update, :destroy]

  # GET /orders
  # GET /orders.json
  def index
    if params[:query].present?
      @orders = Order.search_by_shopify_ids(params[:query]).paginate(page: params[:page], per_page: 10)
    else
      @orders = Order.paginate(page: params[:page], per_page: 10)
    end
  end

  # GET /orders/1
  # GET /orders/1.json
  def show
    @lineitems = @order.lineitems
  end

  # GET /orders/new
  def new
    @order = Order.new
  end

  # GET /orders/1/edit
  def edit
  end

  def cancel_order
    order = Order.find(params[:id])
    order.lineitems.each do |item|
      product = Product.find(item.product_id)
      qty = product.inventory.to_i + item.order_qty
      if product.variant_id.present?
        result = update_inventory(product.variant_id, qty)
      end
      product.inventory = qty
      product.save
    end
    order.status = "Canceled"
    order.save
    redirect_to orders_path, notice: "Order Updated successfully"
  end

  # POST /orders
  # POST /orders.json
  def create
    @order = Order.new(order_params)

    respond_to do |format|
      if @order.save
        format.html { redirect_to @order, notice: 'Order was successfully created.' }
        format.json { render :show, status: :created, location: @order }
      else
        format.html { render :new }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /orders/1
  # PATCH/PUT /orders/1.json
  def update
    respond_to do |format|
      if @order.update(order_params)
        format.html { redirect_to @order, notice: 'Order was successfully updated.' }
        format.json { render :show, status: :ok, location: @order }
      else
        format.html { render :edit }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1
  # DELETE /orders/1.json
  def destroy
    @order.destroy
    respond_to do |format|
      format.html { redirect_to orders_url, notice: 'Order was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_order
      @order = Order.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def order_params
      params.require(:order).permit(:variant_id, :product_id, :order_qty, :remain_qty, :total)
    end

    def update_inventory(variant_id, qty)
      @result = HTTParty.put("https://noor-moden.myshopify.com/admin/api/2019-07/variants/#{variant_id}.json",
        :body => {
                  "variant": {:id=> variant_id,
                    :inventory_quantity=> qty,
                  }
               },
        :headers => {
          'X-Shopify-Access-Token' => ENV['Access_Token']})
    end
end
