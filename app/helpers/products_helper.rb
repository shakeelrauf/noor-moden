module ProductsHelper
    def sorting_options
        [['Sort Products', '']] + [['Sku Desc', 'skuDesc'],['Sku Asc', 'skuAsc'],['Date Desc', 'dateDsc'],['Date Asc', 'dateAsc']]
    end

    def syncing_options
    	[['On', 'true'],['Off', 'false']]
    end

    def sku_type_options
    	[['Restware', 'Restware'],['Damaged', 'Damaged'],['other','other']]
    end

    def modeprofi_options
    	[['Modeprofi On', 'true'],['Modeprofi Off', 'false']]
    end
end
