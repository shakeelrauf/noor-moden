class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :edit, :update, :destroy]
  skip_before_action :verify_authenticity_token, only: %i[webhook_create_order webhook_cancel_order]
  skip_before_action :authenticate_user!, only: %i[webhook_create_order webhook_cancel_order]

  # GET /orders
  # GET /orders.json
  def index
    if params[:query].present?
      @orders = Order.search_by_shopify_ids(params[:query]).paginate(page: params[:page], per_page: 50)
    else
      @orders = Order.paginate(page: params[:page], per_page: 50)
    end
      @orders = @orders.order("created_at desc")
      @sorted_orders = @orders.all.group_by {|item| item.created_at.to_date }
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

  def webhook_create_order
    params["line_items"].each do |line_item|
      product = Product.find_by(variant_id: line_item["variant_id"])
      if product.present?
        quantity = product.inventory.to_i - line_item["quantity"]
        product.inventory = quantity
        product.save
      end
    end
    head 200
  end

  def webhook_cancel_order
    params["line_items"].each do |line_item|
      product = Product.find_by(variant_id: line_item["variant_id"])
      if product.present?
        quantity = product.inventory.to_i + line_item["quantity"]
        product.inventory = quantity
        product.save
      end
    end
    head 200
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

  def print_order
    @order = Order.find(params[:id])
    @real_order_id = params[:real_order_id]
    @lineitems = @order.lineitems
    pdf = WickedPdf.new.pdf_from_string(
      render_to_string('orders/download_order.html.erb', layout: false, locals: { :@order => @order, :@lineitems => @lineitems, :@real_order_id => @real_order_id }),
      :page_size => 'A4',
      :encoding => 'utf8',
      footer: {
        content: render_to_string(
          'orders/footer.html.erb',
          layout: "pdf",
          :encoding => 'utf8',
          :page_size => 'A4',
        )
      }
    )
    # pdf = render_to_string pdf: "new_pdf", template: "orders/download_order.html.erb", encoding: "UTF-8",layout: false, locals: { :@order => @order, :@lineitems => @lineitems }
    send_data pdf, filename: "order-num-#{@order.id}-invoice.pdf"
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

    # def puts_input
    #   puts "Enter input"
    #   get_input = gets.chomp
    #   get_input = get_input.to_s
    #   p1,p2,p3 = "", "", ""
    #   values_array = get_input.split('')
    #   values_array.each do |value|
    #     if value == values_array[0]
    #       p1 += " --- "
    #       p2 += "| #{value} |"
    #       p3 += " === "
    #     else
    #       p1 += "  --- "
    #       p2 += "*| #{value} |"
    #       p3 += "  === "
    #     end
    #   end
    #   puts p1
    #   puts p2
    #   puts p3
    #   puts_input
    # end

end
