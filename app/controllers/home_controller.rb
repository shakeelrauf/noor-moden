# frozen_string_literal: true

class HomeController < AuthenticatedController
  def index
  # 	@result = HTTParty.post("https://noor-moden.myshopify.com/admin/oauth/access_token", 
	 #    :body => {
	 #    'client_id' => "6bb68e71251cc0514ee9c444e5bc8a69",
	 #    'client_secret' =>  "727749ee4043f1c2db24fdbb30637e05",
		# 'code' => '82d042b12f480018c4b8c3e3f82c83a0'})
    @products = ShopifyAPI::Product.find(:all, params: { limit: 10 })
    @webhooks = ShopifyAPI::Webhook.find(:all)
  end
end
