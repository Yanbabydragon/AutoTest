require 'rspec'
require 'airborne'
require_relative '../res_functions/common_functions.rb'

Airborne.configure do |config|
  config.base_url = 'https://api-online-dev.okiela.com'
  config.headers = { 'api-key' => 'web_buyer~2WBET9k9N108'}
end

#pickup_drop_id = 355632

describe 'Flow complete pickup order since buyer placed an order to logistics driver deliver that order to dropoff' do
  before do
    @product_id = 302273
    @quantity = 10
    @facebook_id = "1720298728212660"
    @latitude = "10.952277"
    @longitude = "107.011543"
    @phone = "0909211374"
    @buyername = "Yan"
    @mode_of_payment = "okiela_24_7"
  end

  it 'doing code below' do

    respone = add_product_to_cart(@product_id, @quantity)
    order_id = respone[:order_id]
    order_code = respone[:order_code]

    check_payment_methods(order_id, 2, @mode_of_payment, @latitude, @longitude)

    p "Display list of dropoff API"
    get "/orders/buyer/get_okiela_drop_off_address?current_position_type=latitude_longitude&latitude=#{@latitude}&longitude=#{@longitude}&order_id=#{order_id}"
    dropoff_id = json_body[:address_list][0][:id]
    dropoff_name = json_body[:address_list][0][:dropoff_location_name]

    p "Select dropoff id: #{dropoff_name}"
    param_select_dropoff =  {'params' => { "order_id" => order_id, "dropoff_id" => dropoff_id }, 'auth-token' => buyer_facebook_token }
    put "/orders/buyer/select_okiela_24_7_dropoff", {}, param_select_dropoff

    p "Confirm user info"
    param_update_oll_pickup_order =  {'params' => { "order_id" => order_id, "mode_of_payment" => @mode_of_payment, "okiela_24_7_nationwide_flag" => 3, "name" => @buyername, "phone" => @phone}, 'auth-token' => buyer_facebook_token}
    put "/orders/buyer/update_mode_of_payment", {}, param_update_oll_pickup_order

    order_confirm_code = get_confirm_code(order_code)

    confirm_order_by_sms(order_id, order_confirm_code)

    expect(json_body[:notifications][:status]).to include("success")

    p "oll pickup order code #{order_code}"

    check_order_oll_appear_on_logistics_dashboard("dashboard_pending_confirm","all", order_id)
    
    assign_order("oll_pickup",order_id)

    confirm_assign_order(order_id)

    driver_take_order_from_seller(logictics_driver_id, order_id)
    
    driver_delivery_order_to_final_dropoff(order_id)

    dashboard_confirm_order_deliveried_succefful(order_id)
  end
end