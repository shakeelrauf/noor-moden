module ProductsHelper
    def sorting_options
        [['Sort Products', '']] + [['Model Desc', 'modelDsc'],['Model Asc', 'modelAsc'],['Date Desc', 'dateDsc'],['Date Asc', 'dateAsc']]
    end
end
