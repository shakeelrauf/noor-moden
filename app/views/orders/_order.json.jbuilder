json.extract! order, :id, :variant_id, :product_id, :order_qty, :remain_qty, :total, :created_at, :updated_at
json.url order_url(order, format: :json)
