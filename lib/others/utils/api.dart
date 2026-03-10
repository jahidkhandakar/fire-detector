class Api {
  static const String apiKey  = "";
  static const String baseUrl = "https://firealarm.pranisheba.com.bd";

  // Auth
  static const String register       = "$baseUrl/auth/register/init";
  static const String regVerify      = "$baseUrl/auth/register/verify";
  static const String login          = "$baseUrl/auth/login";
  static const String logVerify      = "$baseUrl/auth/login/verify";
  static const String refreshToken   = "$baseUrl/auth/refresh";
  static const String userDetails    = "$baseUrl/auth/me";
  static const String forgotPass     = "$baseUrl/auth/password/forgot/init";
  static const String forgotComplete = "$baseUrl/auth/password/forgot/complete";
  static const String resetPass      = "$baseUrl/auth/change-password";
  // Alerts
  static const String alerts  = "$baseUrl/alerts/";
  
  // Devices
  static const String devices = "$baseUrl/devices/";

  //Packages
  static const String packages = "$baseUrl/packages/";

  // Orders
  static const String orders = "$baseUrl/orders/";
  static const String ordersUpdateStatus = '$baseUrl/orders/update_status/';
  static const String ordersPaymentNotify = '$baseUrl/orders/payment/notify/';

  // Subscriptions
  static const String subscriptionsMe = '$baseUrl/subscriptions/me';


  //Payments
  static const shurjoInitiate = '$baseUrl/shurjopay/initiate/';
  static const shurjoVerify = '$baseUrl/shurjopay/verify/';
  static const shurjoStatus = '$baseUrl/shurjopay/status/';
  static const shurjoReturn = '$baseUrl/shurjopay/return/';
  static const shurjoCancel = '$baseUrl/shurjopay/cancel/';

  //Acknowledge 
  static const String acknowledge = "$baseUrl/alerts/{id}/acknowledge/";

  //Users
  static const String users = "$baseUrl/users/${"id"}";

  // About
  static const String about = '$baseUrl/content/about/';

  //FAQ
  static const String faq = '$baseUrl/content/faq/';

  //CART
  static const String cart = '$baseUrl/cart/';
  static const String cartCheckout = '$baseUrl/cart/checkout/';
  static const String cartItems = '$baseUrl/cart/items/';
  

}
