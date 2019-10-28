class Order < ApplicationRecord

  include PgSearch::Model
  pg_search_scope :search_by_shopify_ids, against: [:variant_id, :product_id]

end
