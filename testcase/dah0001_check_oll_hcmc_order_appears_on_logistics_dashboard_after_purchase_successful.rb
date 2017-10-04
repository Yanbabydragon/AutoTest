require 'rspec'
require 'airborne'
require_relative '../res_functions/common_functions.rb'

Airborne.configure do |config|
  config.base_url = 'https://api-online-dev.okiela.com'
  config.headers = { 'api-key' => 'web_buyer~2WBET9k9N108'}
end

describe 'checking hcmc oll order appears after buyer buy order success' do
  before do
    @product_id = 302273
    @quantity = 1000
    @facebook_id = "163454787442435"
    @latitude = "10.792780"
    @longitude = "106.691134"
    @phone = "0909211374"
    @buyername = "Yan"
    @mode_of_payment = "okiela_24_7"
    @facebook_id_adminapp = "1720298728212660"
  end

  it 'doing test scripts 1' do
    fb_token_string = buyer_facebook_login[:fb_token_string]
    fb_user_info = buyer_facebook_login[:fb_user_info]

    respone = add_product_to_cart(@product_id, @quantity)
    order_id = respone[:order_id]
    order_code = respone[:order_code]

    check_payment_methods(order_id, 4, @mode_of_payment, @latitude, @longitude)

    p "Display list of dropoff API - GET /orders/buyer/get_okiela_drop_off_address"
    get "/orders/buyer/get_okiela_drop_off_address?current_position_type=latitude_longitude&latitude=#{@latitude}&longitude=#{@longitude}&order_id=#{order_id}"

    dropoff_id = json_body[:address_list][0][:id]
    dropoff_name = json_body[:address_list][0][:dropoff_location_name]

    p "Select dropoff id: #{dropoff_name} - API PUT /orders/buyer/select_okiela_24_7_dropoff"
    param_select_dropoff =  {'params' => { "order_id" => order_id, "dropoff_id" => dropoff_id }, 'auth-token' => fb_token_string }
    put "/orders/buyer/select_okiela_24_7_dropoff", {}, param_select_dropoff

    p "Confirm user info - API PUT /orders/buyer/update_mode_of_payment"
    param_update_oll_hcm_order =  {'params' => { "order_id" => order_id, "mode_of_payment" => @mode_of_payment, "name" => @buyername, "phone" => @phone}, 'auth-token' => fb_token_string }
    put "/orders/buyer/update_mode_of_payment", {}, param_update_oll_hcm_order

    order_confirm_code = get_confirm_code(order_code)

    confirm_order_by_sms(order_id, order_confirm_code)

    expect(json_body[:notifications][:status]).to include("success")

    check_order_oll_appear_on_logistics_dashboard("dashboard_pending_confirm","all", order_id)

    p "OLL HCMC order code: #{order_code}"
  end
end