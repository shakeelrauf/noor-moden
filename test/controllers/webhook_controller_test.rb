require 'test_helper'

class WebhookControllerTest < ActionDispatch::IntegrationTest
  test "should get get_hook" do
    get webhook_get_hook_url
    assert_response :success
  end

end
