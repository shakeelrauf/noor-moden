class SaleOrderHandler
	include ApiCalls
	
	def initialize(options)
		@options = options
    @db_ids, @new_qtys, @line_item_prices, @totals = options[:product_db_id], options[:new_qty], options[:line_item_price], options[:subtotal]
    @actual_qtys, @variants, @qty_hash, @expiry_date = options[:actual_qty], options[:variant_id] , [], options["reservation_expiry_date"][0].to_s
    @expiry_date = DateTime.strptime(@expiry_date,"%m/%d/%Y").to_date if @expiry_date.present?
    @reserve_status = options["reserve_status"]["false"].to_i
    @order_sum, @qty_sum = @totals.map(&:to_f).reduce(:+), @new_qtys.map(&:to_i).reduce(:+)
		@order_type = options["order_type"]
    @paid_type = options["paidtype"]
    @note = options["order_note"]
    @operational_data = []
	end

	def generate_order
    order = Order.create(total: @order_sum, order_qty: @qty_sum, label: @options[:label],reservation_expiry_date: @expiry_date,reserve_status: @reserve_status, paidtype: @paid_type, note: @note  )
		@db_ids.zip(@new_qtys, @totals, @actual_qtys, @line_item_prices).each do |id, new_qty, total, actual_qty, line_item_price|  
      product = Product.find(id)
      qty = product.inventory - new_qty.to_i
      line_item_created = create_line_item(product , new_qty, qty, total, order, line_item_price)
      payment_by_cash(product,new_qty,total,@order_sum,line_item_price,line_item_created) if @order_type == "order" && @paid_type == "Cash"
      payment_by_invoice_cash_or_card(product,new_qty,total,@order_sum,line_item_price,line_item_created) if @order_type == "invoice" &&
                                                          (@paid_type == "Invoice Cash" || @paid_type == "Invoice Card")
      result = update_inventory(product.variant_id, qty)
      if InventorySetting.last.is_syncing == true
        product.inventory = qty
        product.save
      else
        product.inventory = qty
        product.save
      end
    end
    sum = @operational_data.collect{|item| item[:line_item_quantity].to_f * item[:line_item_price].to_f}.sum
    @operational_data.map do |item|
      item[:order_total_price] = sum
      item
    end
    return {order_id: order.id , operational_data: @operational_data}
	end

	private 

	def create_line_item product , new_qty, qty, total, order, line_item_price
		if product.variant_id.present?
      lineitem = Lineitem.create(
        variant_id: product.variant_id,
        shopify_product_id: product.shopify_product_id,
        product_id: product.id,
        order_qty: new_qty,
        remain_qty: qty,
        total: total,
        order_id: order.id,
        sku: product.model_number,
        price: line_item_price
      )
    else
      lineitem = Lineitem.create(
        product_id: product.id,
        order_qty: new_qty,
        remain_qty: qty,
        total: total,
        order_id: order.id,
        sku: product.model_number,
        price: line_item_price
      )
   end
    return lineitem
	end

  def payment_by_invoice_cash_or_card(product,new_qty,total,order_sum,line_item_price,line_item_created)
    line_item_quantity = new_qty.to_i
    line_item_price =line_item_price.to_f
    line_item_total_price = total.to_f
    order_total_price = order_sum.to_f
    modeprofi_inventory = product.modeprofi_inventory
    webhook_inventory = product.inventory
    difference_w_m = webhook_inventory - modeprofi_inventory
    if difference_w_m >= line_item_quantity
      scenario_3_for_bill(webhook_inventory,modeprofi_inventory,difference_w_m,product,line_item_quantity,line_item_price,line_item_total_price,order_total_price,line_item_created)
    else
      new_modeprofi_inventory = modeprofi_inventory - new_qty.to_i
      product.modeprofi_inventory = new_modeprofi_inventory
      product.save
      line_item_created.standard_modiprofi_sold_quantity = line_item_quantity.to_i
      line_item_created.save
      puts("********Total Sold items : #{new_qty.to_i}***********")
      puts("********subtotal of lineitem price : #{line_item_total_price}***********")
      puts("********Total of order price : #{order_total_price}***********")
      if line_item_quantity.to_i > 0
        @operational_data.push({
          new_modeprofi_inventory: new_modeprofi_inventory, 
          difference_w_m_2: new_qty.to_i, 
          line_item_total_price: line_item_total_price, 
          order_total_price: order_total_price, 
          line_item_quantity: line_item_quantity, 
          line_item_price: line_item_price, 
          product: product.model_number,
          order_type: 'Sold'
        }) if @operational_data.is_a?(Array)
      end
    end
  end

  def scenario_3_for_bill(webhook_inventory,modeprofi_inventory,difference_w_m,product,line_item_quantity,line_item_price,line_item_total_price,order_total_price,line_item_created)
      remaining_order_items = modeprofi_inventory - line_item_quantity
      line_item_quantity = line_item_quantity - remaining_order_items.abs
      new_modeprofi_inventory = modeprofi_inventory - line_item_quantity
      product.modeprofi_inventory = new_modeprofi_inventory
      product.save
      line_item_created.standard_modiprofi_sold_quantity = line_item_quantity.to_i
      line_item_created.save
      line_item_total_price = line_item_quantity * line_item_price
      if line_item_quantity.to_i > 0
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

  def payment_by_cash(product,new_qty,total,order_sum,line_item_price,line_item_created)  # "difference_w_m" stands for difference between webhook inventory and modeprofi inventory
    
    line_item_quantity = new_qty.to_i
    webhook_inventory = product.inventory
    modeprofi_inventory = product.modeprofi_inventory
    difference_w_m = webhook_inventory - modeprofi_inventory
    if difference_w_m < line_item_quantity
      scenario_1_cash(difference_w_m,line_item_quantity,modeprofi_inventory,product,order_sum,line_item_price,total,line_item_created)
    end
    # if difference_w_m >= line_item_quantity
    #   scenario_3_cash(difference_w_m,line_item_quantity,modeprofi_inventory,product,order_sum,line_item_price,total)
    # end
  end
  
  def scenario_1_cash(difference_w_m,line_item_quantity,modeprofi_inventory,product,order_sum,line_item_price,total,line_item_created)
    line_item_price =line_item_price.to_f
    line_item_total_price = total.to_f
    order_total_price = order_sum.to_f
    difference_w_m_2 = line_item_quantity - difference_w_m
    new_modeprofi_inventory = modeprofi_inventory - difference_w_m_2
    product.modeprofi_inventory = new_modeprofi_inventory
    product.save
    puts("********Total of RETUORE : #{difference_w_m_2}***********")
    line_item_created.standard_modiprofi_sold_quantity = difference_w_m_2.to_i
    line_item_created.save
    line_item_total_price = line_item_price * difference_w_m_2.to_f
    if difference_w_m_2.to_i > 0
      @operational_data.push({
        new_modeprofi_inventory: new_modeprofi_inventory, 
        difference_w_m_2: difference_w_m_2, 
        line_item_total_price: line_item_total_price, 
        order_total_price: order_total_price, 
        line_item_quantity: difference_w_m_2, 
        line_item_price: line_item_price, 
        product: product.model_number,
        order_type: 'Retoure'
      }) if @operational_data.is_a?(Array)
    end
  end
end