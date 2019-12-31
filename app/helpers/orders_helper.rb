module OrdersHelper

  def line_item_subtotal(lineitems)
    lineitems.collect { |item| item.total.to_f }.sum
  end

  def net_total(lineitems)
  	lineitems.collect {|qty| qty.order_qty * qty.price }.sum
  end

  def net_total_tax(lineitems)
	(line_item_subtotal(lineitems) / 100 * 19).round(3)
  end

  def net_total_after_tax(lineitems)
  	net_total(lineitems) + net_total_tax(lineitems)
  end

end
