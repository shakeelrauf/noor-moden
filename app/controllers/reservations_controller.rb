class ReservationsController < ApplicationController
  before_action :set_order, only: [:show, :edit,:update, :destroy]
  skip_before_action :verify_authenticity_token, only: %i[webhook_create_order webhook_cancel_order]
  skip_before_action :authenticate_user!, only: %i[webhook_create_order webhook_cancel_order]

  include ApiCalls
  include CsvExporter

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
        qty = 0
        order.lineitems.each.with_index do |item,index|
            variant =  Product.find_by(variant_id: item.variant_id)
            qty = calculate_item_update_qty(index,variant,item,qty) #calculate final quantity
            result = update_inventory(item.variant_id, qty) #updating shopify inventory
            variant.inventory = qty
            variant.save
            destroy_else_update_item(item,index,qty)   #delete selected items or update previous items
            quantity << params[:new_qty][index].to_i   
            price << params[:price][index].to_f * params[:new_qty][index].to_f 
            new_qty = params[:new_qty][index].to_i
        end
        if params["product_db_id"].present?
            if params["product_db_id"].length > 0
                params["product_db_id"].each.with_index do |new_item,index| 
                    order_id = order.id
                    create_lineitem_and_update_inventories(index,order_id)
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
        if params["order_type_update"].present?
           order_type_value = params["order_type_update"]
        end
        update = order.update(order_qty: quantity, total: price,reservation_expiry_date: expiry_date,note: params["order_note"],paidtype: order_type_value)
        if params["submit_type"].present?
          if params["submit_type"] == "approve_reservation"
            approve_reservation_for_order_invoice(order)
          else
            redirect_to reservations_path , notice: "Reservation Updated Successfully."
          end
        else
          redirect_to reservations_path , notice: "Reservation Updated Successfully."
        end
    end
 end

  def destroy
    @order.destroy
    respond_to do |format|
      format.html { redirect_to reservations_url, notice: 'Reservation was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def approve_reservation
    order = Order.find(params["order_id"].to_i)
    order.paidtype = params["paidtype"]
    order.reserve_status = false
    order.save
    if order.paidtype.present?
      if order.paidtype == "Cash"
        payment_by_cash(order)
      elsif order.paidtype == "Invoice Cash" || order.paidtype == "Invoice Card"
        payment_by_invoice(order)
      end
    end
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

    def approve_reservation_for_order_invoice(order)
      order.reserve_status = false
      order.save
      if order.paidtype.present?
        if order.paidtype == "Cash"
          payment_by_cash(order)
        elsif order.paidtype == "Invoice Cash" || order.paidtype == "Invoice Card"
          payment_by_invoice(order)
        end
      end
      redirect_to reservations_url , notice: 'Order status is updated.'  
    end

    def destroy_else_update_item(item,index,qty)
      if params[:new_qty][index].to_i == 0            #Destroy Else Update
          Rails.logger.info("**********DESTROYED**#{index}*****variant_id******#{item.variant_id}*********")
          item.destroy
      else
          Rails.logger.info("*******Update********")
          pricing =  params[:price][index]
          item.order_qty = params[:new_qty][index]
          item.remain_qty = qty
          item.price = pricing
          item.save
      end
    end

    def calculate_item_update_qty(index,variant,item,qty)
      actual_qty = variant.inventory
      qty = actual_qty.to_i
      if params[:new_qty][index].to_i < item.order_qty.to_i       #calculating quatity for existing lineitems
          value = item.order_qty.to_i - params[:new_qty][index].to_i
          qty = actual_qty.to_i + value
          Rails.logger.info("*******less with total: #{qty}  and actual is:#{actual_qty.to_i} and value is #{value}*******")
      elsif params[:new_qty][index].to_i > item.order_qty.to_i
          value =  params[:new_qty][index].to_i - item.order_qty.to_i
          qty = actual_qty.to_i - value
          Rails.logger.info("*******greater with total: #{qty}  and actual is:#{actual_qty.to_i} and value is #{value}*****")
      end
      return qty
    end

    def create_lineitem_and_update_inventories(index,order_id)
      variant_id_new = params["variant_new_id"][index].to_i
      model = Product.find_by(variant_id: variant_id_new)
      remaining_qty = model.inventory.to_i - params["new_input_qty"][index].to_i
      result = update_inventory(variant_id_new, remaining_qty)
      model.inventory = remaining_qty
      model.save
      Rails.logger.info("*****model_inventory:#{model.inventory }*******remaining quantity: #{remaining_qty}*******")
      create_lineitem =  Lineitem.create(
          variant_id: variant_id_new,
          shopify_product_id: params["product_id"][index].to_i,
          product_id: params["product_db_id"][index].to_i,
          order_qty: params["new_input_qty"][index].to_i,
          remain_qty: remaining_qty,
          total: params["subtotal"][index].to_f,
          order_id: order_id,
          sku: model.model_number,
          price: params["line_item_price"][index].to_f
      )
    end

    def payment_by_cash(order)
      @operational_data = []
      order.lineitems.order(:created_at).each do |line_item|
        product = Product.find_by(variant_id: line_item.variant_id)
        line_item_quantity = line_item.order_qty.to_i
        webhook_inventory = line_item.remain_qty.to_i +  line_item.order_qty.to_i
        modeprofi_inventory = product.modeprofi_inventory
        difference_w_m = webhook_inventory - modeprofi_inventory
        if difference_w_m < line_item_quantity
          scenario_1_cash(line_item,difference_w_m,line_item_quantity,product,modeprofi_inventory,order)
        end
      end
      if @operational_data.present?
        sum = @operational_data.collect{|item| item[:line_item_quantity].to_f * item[:line_item_price].to_f}.sum
        @operational_data.map do |item|
          item[:order_total_price] = sum
          item
        end
        export_order_to_csv(@operational_data, order.id)
      end
    end

    def payment_by_invoice(order)
      @operational_data = []
      order.lineitems.order(:created_at).each do |line_item|
        product = Product.find_by(variant_id: line_item.variant_id)
        line_item_quantity = line_item.order_qty.to_i
        line_item_price =line_item.price.to_f
        line_item_total_price = line_item.total.to_f
        order_total_price = order.total.to_f
        modeprofi_inventory = product.modeprofi_inventory
        webhook_inventory = line_item.remain_qty.to_i +  line_item.order_qty.to_i
        difference_w_m = webhook_inventory - modeprofi_inventory
        if difference_w_m >= line_item_quantity
          scenario_3_for_bill(line_item,webhook_inventory,modeprofi_inventory,difference_w_m,product,line_item_quantity,line_item_price,line_item_total_price,order_total_price)
        else
          puts("******** Modiprofi Inventory before save:#{product.modeprofi_inventory} ///////// #{line_item_quantity} ")
          new_modeprofi_inventory = modeprofi_inventory - line_item_quantity
          product.modeprofi_inventory = new_modeprofi_inventory
          product.save
          line_item.standard_modiprofi_sold_quantity = line_item_quantity.to_i
          line_item.save
          puts("******** Modiprofi Inventory after save:#{product.modeprofi_inventory} ///////// #{line_item_quantity}  ")
          if line_item_quantity.to_i > 0
            if @operational_data.is_a?(Array)
              @operational_data.push({
                new_modeprofi_inventory: new_modeprofi_inventory, 
                difference_w_m_2: line_item_quantity, 
                line_item_total_price: line_item_total_price, 
                order_total_price: order_total_price, 
                line_item_quantity: line_item_quantity, 
                line_item_price: line_item_price, 
                product: product.model_number,
                order_type: 'Sold'
              })
            end
          end
        end
      end
      export_order_to_csv(@operational_data, order.id) if @operational_data.present?
    end

    def scenario_3_for_bill(line_item,webhook_inventory,modeprofi_inventory,difference_w_m,product,line_item_quantity,line_item_price,line_item_total_price,order_total_price)
      remaining_order_items = modeprofi_inventory - line_item_quantity
      line_item_quantity = line_item_quantity - remaining_order_items.abs
      new_modeprofi_inventory = modeprofi_inventory - line_item_quantity
      product.modeprofi_inventory = new_modeprofi_inventory
      product.save
      line_item_total_price = line_item_quantity * line_item_price
      if line_item_quantity.to_i > 0
        line_item.standard_modiprofi_sold_quantity = line_item_quantity.to_i
        line_item.save
        @operational_data.push({
          new_modeprofi_inventory: new_modeprofi_inventory, 
          difference_w_m_2: line_item_quantity, 
          line_item_total_price: line_item_total_price, 
          order_total_price: order_total_price, 
          line_item_quantity: line_item_quantity, 
          line_item_price: line_item_price, 
          product: product.model_number,
          order_type: 'Sold'
        }) if @operational_data.is_a?(Array)
      end
      if remaining_order_items.to_i < 0
        remaining_order_items = remaining_order_items.abs
      end
      line_item_total_price = remaining_order_items * line_item_price
      sku_type =SkuType.last.sku_type
      if remaining_order_items.to_i > 0
        @operational_data.push({
          new_modeprofi_inventory: new_modeprofi_inventory, 
          difference_w_m_2: remaining_order_items, 
          line_item_total_price: line_item_total_price, 
          order_total_price: order_total_price, 
          line_item_quantity: remaining_order_items, 
          line_item_price: line_item_price, 
          product: sku_type,
          order_type: 'Sold'
        }) if @operational_data.is_a?(Array)
      end
    end
    def scenario_1_cash(line_item,difference_w_m,line_item_quantity,product,modeprofi_inventory,order)
      line_item_price = line_item.price.to_f
      line_item_total_price = line_item.total.to_f
      order_total_price = order.total.to_f
      difference_w_m_2 = line_item_quantity - difference_w_m
      new_modeprofi_inventory = modeprofi_inventory - difference_w_m_2
      product.modeprofi_inventory = new_modeprofi_inventory
      product.save
      line_item.standard_modiprofi_sold_quantity = difference_w_m_2.to_i
      line_item.save
      Rails.logger.info("********Total Retoure items : #{difference_w_m_2}***********")
      Rails.logger.info("********subtotal of lineitem price : #{line_item_total_price}***********")
      Rails.logger.info("********Total of order price : #{order_total_price}***********")
      line_item_total_price = line_item_price * difference_w_m_2.to_f
      if difference_w_m_2.to_i > 0
        if @operational_data.is_a?(Array)
          @operational_data.push({
            new_modeprofi_inventory: new_modeprofi_inventory, 
            difference_w_m_2: difference_w_m_2, 
            line_item_total_price: line_item_total_price, 
            order_total_price: order_total_price, 
            line_item_quantity: difference_w_m_2, #line_item_ordered quantity after calculation
            line_item_price: line_item_price, 
            product: product.model_number,
            order_type: 'Retoure'
          })
        end
      end
    end

end