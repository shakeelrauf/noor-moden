require 'test_helper'

class CustomerMailerTest < ActionMailer::TestCase
  test "send_shopify_signup_notification" do
    mail = CustomerMailer.send_shopify_signup_notification
    assert_equal "Send shopify signup notification", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
