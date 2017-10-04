require 'rspec'
require 'airborne'
require_relative '../res_functions/common_functions.rb'

Airborne.configure do |config|
  config.base_url = 'https://api-online-dev.okiela.com'
  config.headers = { 'api-key' => 'web_buyer~2WBET9k9N108'}
end

#delivery_drop_id = 355632

describe 'Flow complete delivery order since buyer placed an order to logistics driver deliver that order to dropoff' do
  before do
    @product_id = 302273
    @quantity = 10
    @facebook_id = "1720298728212660"
    @latitude = "10.952277"
    @longitude = "107.011543"
    @phone = "0909211374"
    @buyername = "Yan"
    @mode_of_payment = "okiela_24_7"
    @expect_pickup_time = Time.now.to_s
    @dropoff_id = 359682
  end

  it 'doing code below' do
    fb_user_info = buyer_facebook_login[:fb_user_info]

    respone = add_product_to_cart(@product_id, @quantity)
    order_id = respone[:order_id]
    order_code = respone[:order_code]

    check_payment_methods(order_id, 2, @mode_of_payment, @latitude, @longitude)
    
    get "/orders/#{order_id}/dynamic_mode_of_payment?order_id=#{order_id}&latitude=#{@latitude}&longitude=#{@longitude}"
    get_shipping_fee_amount = json_body[:mode_of_payments][0][:shipping_fee_amount]

    p "Confirm user info"
    param_update_select_oll_deliver =  {'params' => { "order_id" => order_id, "mode_of_payment" => @mode_of_payment, "name" => @buyername, "phone" => @phone, "street" => @street, "city" => @city, "district" => @district, "okiela_24_7_nationwide_flag" => 2, "shipping_fee_amount" => get_shipping_fee_amount}, 'auth-token' => buyer_facebook_token }
    put "/orders/buyer/update_mode_of_payment", {}, param_update_select_oll_deliver

    order_confirm_code = get_confirm_code(order_code)

    confirm_order_by_sms(order_id, order_confirm_code)

    expect(json_body[:notifications][:status]).to include("success")
    
    p "oll delivery order code: #{order_code} - shipping fee: #{get_shipping_fee_amount}"

    check_order_oll_appear_on_logistics_dashboard("dashboard_pending_confirm","all", order_id)

    assign_order("oll_delivery",order_id)

    confirm_assign_order(order_id)

    driver_take_order_from_seller(logictics_driver_id, order_id)
    
    driver_delivery_order_to_final_dropoff(order_id)

    dashboard_confirm_order_deliveried_succefful(order_id)
  end
end