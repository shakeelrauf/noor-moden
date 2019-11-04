class Product < ApplicationRecord

  include PgSearch::Model
  pg_search_scope :search_by_shopify_ids, against: [:variant_id, :shopify_product_id, :inventory, :model_number]

end
