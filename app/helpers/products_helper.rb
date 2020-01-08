module ProductsHelper
    def sorting_options
        [['Sort Products', '']] + [['Sku Desc', 'skuDesc'],['Sku Asc', 'skuAsc'],['Date Desc', 'dateDsc'],['Date Asc', 'dateAsc']]
    end
end
