#yanbabydragon
#FB_ID_BUYER = "163454787442435"

#hakunabr0
FB_ID_BUYER = "1720298728212660"
FB_ID_ADMINS = "1720298728212660"

#############   Logis Info   #############
#dropoff id for DongNai OLL Order
DN_DROPOFF_ID = 359682
EXPECTE_TIME = Time.now

#logistics dashboard
PHONE_DASHBOARD_LOGISTICS = "0978838249"
PASSWORD_DASHBOARD_LOGISTICS = "889052"

#logictics driver
PHONE_DRIVER_LOGISTICS = "0978838250"
PASSWORD_DRIVER_LOGISTICS = "123456"

#product and shop id using for test
TEST_PRODUCT2 = 351015
SHOP_ID2 = 350974

def buyer_facebook_login
  @buyer_facebook_login ||= begin
    p 'login buyer app'
    get "/auth/facebook?facebook_id=#{FB_ID_BUYER}"
    fb_token_string = json_body[:api_token][:token_string]
    fb_user_info = json_body[:user]
    {fb_token_string:fb_token_string, fb_user_info:fb_user_info}
  end
end

def buyer_facebook_user_info
  @buyer_facebook_user_info ||= begin
    buyer_facebook_login[:fb_user_info]
  end
end

def buyer_facebook_token
  @buyer_facebook_token ||= begin
    buyer_facebook_login[:fb_token_string]
  end
end

def admins_facebook_login_token
  @admins_facebook_login ||= begin
    p 'Login admins app to get confirmation code'
    get "/auth/facebook?facebook_id=#{FB_ID_ADMINS}"
    json_body[:api_token][:token_string]

    #this code return token string only for futher use
  end
end

def get_confirm_code(order_code)
  #ad_token_string = admins_facebook_login[:ad_token_string]
  get "/admins/orders/get_confirm_code?keyword=#{order_code}", {'auth-token' => admins_facebook_login_token}
  order_confirm_code = json_body[:orders][:items][0][:order_confirm_phone]
  order_confirm_code
end

def confirm_order_by_sms(order_id, order_confirm_code)
  param_confirm_by_sms = {'params'=> {"order_id" => order_id, "code" => order_confirm_code}, 'auth-token' => buyer_facebook_token}
  put "/orders/buyer/confirm_by_sms", {}, param_confirm_by_sms
end

def logictics_dashboard_login
  @login_logictics_dashboard ||= begin
    p 'login logistics dashboard'
    params_logistics_dashboard = {'params' => {'phone' => PHONE_DASHBOARD_LOGISTICS, 'password' => PASSWORD_DASHBOARD_LOGISTICS}}
    post '/auth/login_logistic', {}, params_logistics_dashboard
    dash_token_string = json_body[:api_token][:token_string]
    {dash_token_string:dash_token_string}
  end
end

def logictics_dashboard_token
  @logictics_dashboard_token ||= begin
    logictics_dashboard_login[:dash_token_string]
  end
end

def logictics_driver_login
  @logictics_driver_login ||= begin
    p 'login logistics app'
    params_logistics_driver = {'params' => {'phone' => PHONE_DRIVER_LOGISTICS, 'password' => PASSWORD_DRIVER_LOGISTICS}}
    post '/auth/login_logistic', {}, params_logistics_driver
    logis_token_string = json_body[:api_token][:token_string]
    logis_driver_id = json_body[:logistic_user][:id]
    {logis_token_string:logis_token_string, logis_driver_id:logis_driver_id}
  end
end

def logictics_driver_token
  @logictics_driver_token ||= begin
    logictics_driver_login[:logis_token_string]
  end
end

def logictics_driver_id
  @logictics_driver_id ||= begin
    logictics_driver_login[:logis_driver_id]
  end
end

def add_product_to_cart(product_id, quantity)
  p "Add products to order"
  param_create_order = {'params' => {"product_id" => product_id, "quantity" => quantity, "check_exist_cart" => "true"}, 'auth-token' => buyer_facebook_token}
  post "/orders/buyer/add_product", {}, param_create_order
  order_code = json_body[:order][:code]
  order_id = json_body[:order][:id]
  final_price_after_tax = json_body[:order][:final_price_after_tax]
  {order_code:order_code, order_id:order_id, final_price_after_tax:final_price_after_tax}
end

def check_payment_methods(order_id, nums, mode_of_payment, latitude, longitude)
  get "/orders/#{order_id}/dynamic_mode_of_payment?order_id=#{order_id}&latitude=#{latitude}&longitude=#{longitude}"
  mode_of_payments = json_body[:mode_of_payments]
  expect(mode_of_payments.count).to eq(nums)
  items = mode_of_payments.map{|a| a[:mode_of_payment] }
  expect(items).to include(mode_of_payment)
end

def check_order_oll_appear_on_logistics_dashboard(order_type, oll_type, order_id)
  p 'verify order appear on logis board'
  get "/logistics/orders?order_type=#{order_type}&oll_type=#{oll_type}&view_type=dashboard_general_info&order_direction=desc", {'auth-token' => logictics_dashboard_token}
  dash_first_order_id = json_body[:orders][:items][0][:id]
  expect(dash_first_order_id).to eq(order_id)
end

def assign_order(order_mode, order_id)
  p "assign delivery order to logistics driver"
  if order_mode == "oll_delivery"
    params_info_logistics_driver = {'params' => {'order_id' => order_id, 'payoo_id' => 123456789, 'final_dropoff_id' => DN_DROPOFF_ID, 'expect_pickup_time' => EXPECTE_TIME , 'pickup_driver_id' => logictics_driver_id, 'deliver_driver_id' => logictics_driver_id, 'note' => "test assign oll delivery"}, 'auth-token' => logictics_dashboard_token}
    put '/logistics/logistic_assign_driver', {}, params_info_logistics_driver
  elsif order_mode == "oll_pickup"
    params_info_logistics_driver = {'params' => {'order_id' => order_id, 'payoo_id' => 123456789, 'expect_pickup_time' => EXPECTE_TIME , 'pickup_driver_id' => logictics_driver_id, 'deliver_driver_id' => logictics_driver_id, 'note' => "test assign oll pickup"}, 'auth-token' => logictics_dashboard_token}
    put '/logistics/logistic_assign_driver', {}, params_info_logistics_driver
  elsif order_mode == "oll_hcmc"
    params_info_logistics_driver = {'params' => {'order_id' => order_id, 'payoo_id' => 123456789, 'expect_pickup_time' => EXPECTE_TIME , 'pickup_driver_id' => logictics_driver_id, 'deliver_driver_id' => logictics_driver_id, 'note' => "test assign oll hcmc"}, 'auth-token' => logictics_dashboard_token}
    put '/logistics/logistic_assign_driver', {}, params_info_logistics_driver
  elsif order_mode == "oll_nationwide"
    params_info_logistics_driver = {'params' => {'order_id' => order_id, 'payoo_id' => 123456789, 'expect_pickup_time' => EXPECTE_TIME , 'pickup_driver_id' => logictics_driver_id, 'deliver_driver_id' => logictics_driver_id, 'note' => "test assign oll nationwide"}, 'auth-token' => logictics_dashboard_token}
    put '/logistics/logistic_assign_driver', {}, params_info_logistics_driver
  else raise 'cant assign order'
  end
end

def confirm_assign_order(order_id)
  p "confirm assign order"
  params_confirm_assign_order = {'params' => {'order_id' => order_id}, 'auth-token' => logictics_dashboard_token}
  put '/logistics/dashboard_confirm_order', {}, params_confirm_assign_order
end

def driver_take_order_from_seller(logictics_driver_id, order_id)
  p "driver take order from seller"
  params_driver_keep_order = {'params' => {'id' => logictics_driver_id,'order_id' => order_id}, 'auth-token' => logictics_driver_token}
  put '/logistics/staff_confirm_keep_order', {}, params_driver_keep_order
end

def driver_delivery_order_to_final_dropoff(order_id)
  p "driver delivery delivery order to drop-off"
  params_driver_delivery_order = {'params' => {'order_id' => order_id}, 'auth-token' => logictics_driver_token}
  put '/logistics/staff_confirm_delivered_order?order_id', {}, params_driver_delivery_order  
end

def dashboard_confirm_order_deliveried_succefful(order_id)
    p "dashboard confirmed successful delivery delivery order"
    params_confirm_delivery_order = {'params' => {'order_id' => order_id, 'flag_confirm' => "drop_off_confirmed"}, 'auth-token' => logictics_dashboard_token}
    put '/logistics/manager_confirmed_dropoff_order', {},  params_confirm_delivery_order
end
# def get_payoo_code(buyername, buyerphone, cash, order_code)
# #   params_payoo_code = {'name' => buyername ,'phone' => buyerphone,'title' => "",'cash' => cash, 'note' => "DEV payoo order" ,'order_no' => order_code}
# #   post 'https://logisticsboard.okiela.com/dev/payoo/payment', {}, params_payoo_code
# #   p json_bodyx  
# #   payoo_id = json_body["BillingCode"]
# end

# def update_mode_of_payment(params)
#   rq_params =  {'params' => params, 'auth-token' => buyer_facebook_token}
#   put "/orders/buyer/update_mode_of_payment", {}, rq_params
# end