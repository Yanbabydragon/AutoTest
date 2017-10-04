require 'rspec'
require 'airborne'
require_relative '../res_functions/common_functions.rb'

Airborne.configure do |config|
  config.base_url = 'https://api-online-dev.okiela.com'
  config.headers = { 'api-key' => 'web_buyer~2WBET9k9N108'}
end

#hcmc_drop_id = 355632

describe 'Flow complete Nationwide order since buyer placed an order to logistics driver deliver that order to buyer' do
  before do
        @product_id = 302273
        @quantity = 1000
        @city = "Hải Phòng"
        @district = "Ngô Quyền"
        @latitude = "20.858416"
        @longitude = "106.698237"
        @phone = "0909211374"
        @buyername = "Yan"
        @street = "abc"
        @mode_of_payment = "okiela_24_7"
        @expect_pickup_time = Time.now.to_s
  end

  it 'doing code blow' do

    respone = add_product_to_cart(@product_id, @quantity)
    order_id = respone[:order_id]
    order_code = respone[:order_code]

    check_payment_methods(order_id, 1, @mode_of_payment, @latitude, @longitude)

    p "Confirm user info"
    param_select_nationwide_location =  {'params' => { "order_id" => order_id, "mode_of_payment" => @mode_of_payment, "name" => @buyername, "phone" => @phone, "street" => @street, "city" => @city, "district" => @district, "okiela_24_7_nationwide_flag" => 1 }, 'auth-token' => buyer_facebook_token}
    put "/orders/buyer/update_mode_of_payment", {}, param_select_nationwide_location

    order_confirm_code = get_confirm_code(order_code)

    confirm_order_by_sms(order_id, order_confirm_code)

    expect(json_body[:notifications][:status]).to include("success")

    p "oll nationwide order code: #{order_code}"

    check_order_oll_appear_on_logistics_dashboard("dashboard_pending_confirm","all", order_id)   
    
    assign_order("oll_nationwide",order_id)

    confirm_assign_order(order_id)

    driver_take_order_from_seller(logictics_driver_id, order_id)
    
    driver_delivery_order_to_final_dropoff(order_id)

    dashboard_confirm_order_deliveried_succefful(order_id)
  end
end