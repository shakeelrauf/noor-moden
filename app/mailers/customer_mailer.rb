class CustomerMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.customer_mailer.send_shopify_signup_notification.subject
  #
  def send_shopify_signup_notification(params)
    @greeting = "Hi"
    @name = params[:first_name]
    @email = params[:email]
    mail to: "talha.waseem@phaedrasolutions.com", subject: "New Customer Signup on your store"
  end

  def products_exported(file)
    attachments['Products.xlsx'] = file
    mail to: "talha.waseem@phaedrasolutions.com", subject: "Products Exported"
  end

  def products_imported(file_path)
    attachments['Products.xlsx'] = File.read(file_path, :encoding => 'BINARY')
    mail to: "talha.waseem@phaedrasolutions.com", subject: "Products Imported"
  end
end
