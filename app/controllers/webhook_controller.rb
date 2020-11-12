class WebhookController < ApplicationController

	skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

	def get_hook
		# This token I get from https://noor-moden.myshopify.com/admin/private/apps, password is shopify-acess-token
		# @result = HTTParty.post("#{ENV['SHOPIFY_API_URL']}/customers.json",
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

  def validate_vat_id
    render json: { vat_valid: verify_vat}
  end

  private

  def get_license_url(file_name)
    "http://" + request.host + "/license_files/" + file_name
  end

  def verify_vat
    country_code = params[:vat_id][0..1]
    vat_id = params[:vat_id][2..params[:vat_id].length]
    url = "http://ec.europa.eu/taxation_customs/vies/services/checkVatService"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = false

    data = <<-EOF
    <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:ec.europa.eu:taxud:vies:services:checkVat:types">
        <soapenv:Header/>
        <soapenv:Body>
          <urn:checkVat>
             <urn:countryCode>#{country_code}</urn:countryCode>
             <urn:vatNumber>#{vat_id}</urn:vatNumber>
          </urn:checkVat>
         </soapenv:Body>
        </soapenv:Envelope>
    EOF

    headers = {
        'Content-Type' => 'text/xml; charset=utf-8'
    }

    result = http.post(uri.path, data, headers)
    result.body.include?("<valid>true</valid>")
  rescue StandardError
    return false
  end

end
