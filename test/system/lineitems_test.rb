require "application_system_test_case"

class LineitemsTest < ApplicationSystemTestCase
  setup do
    @lineitem = lineitems(:one)
  end

  test "visiting the index" do
    visit lineitems_url
    assert_selector "h1", text: "Lineitems"
  end

  test "creating a Lineitem" do
    visit lineitems_url
    click_on "New Lineitem"

    fill_in "Order", with: @lineitem.order_id
    fill_in "Order qty", with: @lineitem.order_qty
    fill_in "Product", with: @lineitem.product_id
    fill_in "Remain qty", with: @lineitem.remain_qty
    fill_in "Sku", with: @lineitem.sku
    fill_in "Total", with: @lineitem.total
    fill_in "Variant", with: @lineitem.variant_id
    click_on "Create Lineitem"

    assert_text "Lineitem was successfully created"
    click_on "Back"
  end

  test "updating a Lineitem" do
    visit lineitems_url
    click_on "Edit", match: :first

    fill_in "Order", with: @lineitem.order_id
    fill_in "Order qty", with: @lineitem.order_qty
    fill_in "Product", with: @lineitem.product_id
    fill_in "Remain qty", with: @lineitem.remain_qty
    fill_in "Sku", with: @lineitem.sku
    fill_in "Total", with: @lineitem.total
    fill_in "Variant", with: @lineitem.variant_id
    click_on "Update Lineitem"

    assert_text "Lineitem was successfully updated"
    click_on "Back"
  end

  test "destroying a Lineitem" do
    visit lineitems_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Lineitem was successfully destroyed"
  end
end
