class Order < ApplicationRecord

  include PgSearch::Model
  pg_search_scope :search_by_shopify_ids, against: [:id, :status, :created_at], associated_against: {
    lineitems: [:sku, :shopify_product_id, :variant_id]
	}
  has_many :lineitems, dependent: :destroy

end
