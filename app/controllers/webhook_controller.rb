class WebhookController < ApplicationController

	skip_before_action :verify_authenticity_token

	def get_hook
		# This token I get from https://noor-moden.myshopify.com/admin/private/apps, password is shopify-acess-token
		# @result = HTTParty.post("https://noor-moden.myshopify.com/admin/api/2019-07/customers.json",
	 #    :body => { 
  #               "customer": {:first_name=> params["first_name"], 
	 #    						:last_name=> params["last_name"], 
	 #    						:email=> params["email"], 
	 #    						password: params["email"]
	 #    					}
	 #           },
	 #    :headers => {
		#     'X-Shopify-Access-Token' => ENV['Access_Token']})
    if params[:license_file0].present?
      uploaded_io = params[:license_file0]
      File.open(Rails.root.join('public', 'license_files', uploaded_io.original_filename), 'wb') do |file|
        file.write(uploaded_io.read)
      end
      render json: { link: get_license_url(uploaded_io.original_filename) }
    else
      render json: { link: "" }
    end
	end

  private

  def get_license_url(file_name)
    "http://" + request.host + "/license_files/" + file_name
  end

end
