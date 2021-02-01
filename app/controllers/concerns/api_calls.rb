module ApiCalls
  extend ActiveSupport::Concern

  def update_inventory(variant_id, qty)
    update_inventory_on_store(ENV['SHOPIFY_API_URL'],ENV['Access_Token'], variant_id, qty)
    update_inventory_on_store(ENV['SHOPIFY_API_URL2'],ENV['Access_Token2'], variant_id, qty)
  end

  def update_inventory_on_store url,  access_token, variant_id, qty
    inventory_levels = get_variant_on_store(url, access_token, variant_id)
    if inventory_levels.code == 200
      inventory_item_id = inventory_levels.parsed_response["variant"]["inventory_item_id"]
      inventory_levels = HTTParty.get("#{url}/inventory_levels.json",
        :query => {
                    "inventory_item_ids": inventory_item_id,
                  },
        :headers => {
          'X-Shopify-Access-Token' => access_token})
      if inventory_levels.code == 200 && inventory_levels.parsed_response["inventory_levels"].count > 0
        adjust_items = inventory_levels.parsed_response["inventory_levels"].first
        set_inventory_levels_qty = HTTParty.post("#{url}/inventory_levels/set.json",
        :body => {
          "location_id": adjust_items["location_id"],
          "inventory_item_id": adjust_items["inventory_item_id"],
          "available": qty,
        },
        :headers => {
          'X-Shopify-Access-Token' => access_token})
      end
    end
  end

  def update_variant_price(variant_id, qty, price)
    update_variant_price_on_store(ENV['SHOPIFY_API_URL'], ENV['Access_Token'], variant_id, qty, price)
    update_variant_price_on_store(ENV['SHOPIFY_API_URL2'], ENV['Access_Token2'], variant_id, qty, price)
  end

  def update_variant_price_on_store url, access_token, variant_id, qty, price
    @result = HTTParty.put("#{url}/variants/#{variant_id}.json",
      :body => { 
                "variant": {:id=> variant_id, 
                  :inventory_quantity=> qty,
                  :price => price
                }
             },
      :headers => {
        'X-Shopify-Access-Token' => access_token})
  end

  def update_customer(customer_id,country,accepts_marketing)
    update_customer_on_store ENV['SHOPIFY_API_URL'], ENV['Access_Token'], customer_id, country, accepts_marketing    
    update_customer_on_store ENV['SHOPIFY_API_URL2'], ENV['Access_Token2'], customer_id, country, accepts_marketing    
  end

  def update_customer_on_store url, access_token, customer_id, country, accepts_marketing
    tags = ["approved"]
    german_countries = %w(austria belgium germany liechtenstein luxembourg switzerland)
    german_countries.include?(country.downcase) ? tags.push("de") : tags.push("en")

    @result = HTTParty.put("#{url}/customers/#{customer_id}.json",
       :body => {
           "customer": {:id=> customer_id,
                       :tags=> tags.uniq.join(","),
                        :tax_exempt=> country.downcase != "germany",
                        :accepts_marketing => accepts_marketing
           }
       },
       :headers => {
           'X-Shopify-Access-Token' => access_token})
  end

  def delete_variant(product_id, variant_id)
    @result = HTTParty.delete("#{ENV['SHOPIFY_API_URL']}/products/#{product_id}/variants/#{variant_id}.json",
      :headers => {
        'X-Shopify-Access-Token' => ENV['Access_Token']})
  end


  def delete_variant(product_id, variant_id)
    @result = HTTParty.delete("#{ENV['SHOPIFY_API_URL']}/products/#{product_id}/variants/#{variant_id}.json",
      :headers => {
        'X-Shopify-Access-Token' => ENV['Access_Token']})
  end

  def get_variant(variant_id)
    inventory_levels = HTTParty.get("#{ENV['SHOPIFY_API_URL']}/variants/#{variant_id}.json",
      :headers => {
        'X-Shopify-Access-Token' => ENV['Access_Token']})
  end


  def get_variant_on_store(url, access_token, variant_id)
    inventory_levels = HTTParty.get("#{url}/variants/#{variant_id}.json",
      :headers => {
        'X-Shopify-Access-Token' => access_token})
  end

end
