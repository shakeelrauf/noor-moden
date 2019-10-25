json.extract! product, :id, :shopify_product_id, :inventory, :barcode, :price, :created_at, :updated_at
json.url product_url(product, format: :json)
