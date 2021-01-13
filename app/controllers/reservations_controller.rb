class ReservationsController < ApplicationController
  before_action :set_order, only: [:show, :edit,:update, :destroy]
  skip_before_action :verify_authenticity_token, only: %i[webhook_create_order webhook_cancel_order]
  skip_before_action :authenticate_user!, only: %i[webhook_create_order webhook_cancel_order]

  def index
    if params[:query].present?
      @orders = Order.search_by_shopify_ids(params[:query]).paginate(page: params[:page], per_page: 50)
    else
      @orders = Order.paginate(page: params[:page], per_page: 50)
    end
      @orders = @orders.order("created_at desc")
      @sorted_orders = @orders.all.group_by {|item| item.created_at.to_date }
  end

  def show
    @lineitems = @order.lineitems
  end

  def new
    @order = Order.new
  end

  def edit
  end

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

 def update_reservation
    order = Order.find(params[:format].to_i)
    if order.lineitems.count > 0
        quantity = []
        price = []
        order.lineitems.each.with_index do |item,index|
            variant =  Product.find_by(variant_id: item.variant_id)
            actual_qty = variant.inventory
            if params[:new_qty][index].to_i < item.order_qty.to_i       #calculating quatity for existing lineitems
                value = item.order_qty.to_i - params[:new_qty][index].to_i
                qty = actual_qty.to_i + value
                puts("*******less with total: #{qty}  and actual is:#{actual_qty.to_i} and value is #{value}*******")
            elsif params[:new_qty][index].to_i > item.order_qty.to_i
                value =  params[:new_qty][index].to_i - item.order_qty.to_i 
                qty = actual_qty.to_i - value
                puts("*******greater with total: #{qty}  and actual is:#{actual_qty.to_i} and value is #{value}*****")
            else
                qty = actual_qty.to_i
            end
            result = update_inventory(item.variant_id, qty)
            variant.inventory = qty
            variant.save
            if params[:new_qty][index].to_i == 0            #Destroy Else Update
                puts("**********DESTROYED*******variant_id******#{item.variant_id}*********")
                item.destroy
            else
                puts("*******Update********")
                pricing =  params[:price][index]
                item.order_qty = params[:new_qty][index].dup
                item.price = pricing
                item.save 
            end
            quantity << params[:new_qty][index].to_i   
            price << params[:price][index].to_f * params[:new_qty][index].to_f 
            new_qty = params[:new_qty][index].to_i
        end
        if params["product_db_id"].present?
            if params["product_db_id"].length > 0
                params["product_db_id"].each.with_index do |new_item,index| 
                    variant_id_new = params["variant_new_id"][index].to_i
                    model = Product.find_by(variant_id: variant_id_new)
                    remaining_qty = model.inventory.to_i - params["new_input_qty"][index].to_i
                    result = update_inventory(variant_id_new, remaining_qty)
                    model.inventory = remaining_qty
                    model.save
                    puts("*****model_inventory:#{model.inventory }*******remaining quantity: #{remaining_qty}*******")
                    create_lineitem =  Lineitem.create(
                        variant_id: variant_id_new,
                        shopify_product_id: params["product_id"][index].to_i,
                        product_id: params["product_db_id"][index].to_i,
                        order_qty: params["new_input_qty"][index].to_i,
                        remain_qty: remaining_qty,
                        total: params["subtotal"][index].to_f,
                        order_id: order.id,
                        sku: model.model_number,
                        price: params["line_item_price"][index].to_f
                    )
                    price << params["line_item_price"][index].to_f * params["new_input_qty"][index].to_f
                    quantity << params["new_input_qty"][index].to_i
                end
            end
        end
        expiry_date = params["reservation_expiry_date"][0].to_s
        if expiry_date.present?
          expiry_date=DateTime.strptime(expiry_date,"%m/%d/%Y").to_date
        end
        price = price.sum
        quantity = quantity.sum
        order = order.update(order_qty: quantity, total: price,reservation_expiry_date: expiry_date,note: params["order_note"])
    end
    redirect_to reservations_path , notice: "Reservation Updated Successfully."
 end
#   def update
#     respond_to do |format|
#       if @order.update(order_params)
#         format.html { redirect_to @order, notice: 'Reservation was successfully updated.' }
#         format.json { render :show, status: :ok, location: @order }
#       else
#         format.html { render :edit }
#         format.json { render json: @order.errors, status: :unprocessable_entity }
#       end
#     end
#   end

  def destroy
    @order.destroy
    respond_to do |format|
      format.html { redirect_to reservations_url, notice: 'Reservation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  def approve_reservation
    @order = Order.find(params["format"].to_i)
    @order.reserve_status = false
    @order.save
    redirect_to reservations_url , notice: 'Order status is updated.'  
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
      inventory_levels = get_variant(variant_id)
      if inventory_levels.code == 200
        inventory_item_id = inventory_levels.parsed_response["variant"]["inventory_item_id"]
        inventory_levels = HTTParty.get("#{ENV['SHOPIFY_API_URL']}/inventory_levels.json",
          :query => {
                      "inventory_item_ids": inventory_item_id,
                    },
          :headers => {
            'X-Shopify-Access-Token' => ENV['Access_Token']})
        if inventory_levels.code == 200 && inventory_levels.parsed_response["inventory_levels"].count > 0
          adjust_items = inventory_levels.parsed_response["inventory_levels"].first
          set_inventory_levels_qty = HTTParty.post("#{ENV['SHOPIFY_API_URL']}/inventory_levels/set.json",
          :body => {
            "location_id": adjust_items["location_id"],
            "inventory_item_id": adjust_items["inventory_item_id"],
            "available": qty,
          },
          :headers => {
            'X-Shopify-Access-Token' => ENV['Access_Token']})
        end
      end
    end

  def get_variant(variant_id)
    
    inventory_levels = HTTParty.get("#{ENV['SHOPIFY_API_URL']}/variants/#{variant_id}.json",
      :headers => {
        'X-Shopify-Access-Token' => ENV['Access_Token']})
  end
end
