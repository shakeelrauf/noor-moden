module ProductsHelper
    def sorting_options
        [['Sort Products', '']] + [['Sku Desc', 'skuDesc'],['Sku Asc', 'skuAsc'],['Date Desc', 'dateDsc'],['Date Asc', 'dateAsc']]
    end

    def syncing_options
    	[['On', 'true'],['Off', 'false']]
    end

    def modeprofi_options
    	[['Modeprofi On', 'true'],['Modeprofi Off', 'false']]
    end

    def reserve_inventory(product)
        quantity = []
        variant = product.variant_id
        line_item = Lineitem.where(variant_id: variant)
        line_item&.each do |item|
           if item&.order&.reserve_status == true && item&.order&.status == "Processed"
            quantity  << item.order_qty.to_i
           end
        end
        quantity = quantity.sum
        return quantity
    end
end
