module OrdersHelper

  def line_item_subtotal(lineitems)
    lineitems.collect { |item| item.total.to_f }.sum
  end

end
