# Preview all emails at http://localhost:3000/rails/mailers/customer_mailer
class CustomerMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/customer_mailer/send_shopify_signup_notification
  def send_shopify_signup_notification
    CustomerMailer.send_shopify_signup_notification
  end

  # Preview this email at http://localhost:3000/rails/mailers/customer_mailer/products_imported
  def products_imported
    CustomerMailer.products_imported
  end

  # Preview this email at http://localhost:3000/rails/mailers/customer_mailer/products_exported
  def products_exported
    CustomerMailer.products_exported
  end

end
