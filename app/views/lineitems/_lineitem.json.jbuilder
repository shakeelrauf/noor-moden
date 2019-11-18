json.extract! lineitem, :id, :order_id, :product_id, :variant_id, :order_qty, :remain_qty, :total, :sku, :created_at, :updated_at
json.url lineitem_url(lineitem, format: :json)
