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
end
