class Api {
  static const String apiKey  = "";
  static const String baseUrl = "https://firealarm.pranisheba.com.bd";

  // Auth
  static const String register     = "$baseUrl/auth/register";
  static const String login        = "$baseUrl/auth/login";
  static const String refreshToken = "$baseUrl/auth/refresh";
  static const String userDetails  = "$baseUrl/auth/me";

  // Alerts
  static const String alerts  = "$baseUrl/alerts/";
  
  // Devices
  static const String devices = "$baseUrl/devices/";

  //Packages
  static const String packages = "$baseUrl/packages/";

  // Orders
  static const String orders = "$baseUrl/orders/";

  //Payments
  static const shurjoInitiate = '$baseUrl/shurjopay/initiate/';
  static const shurjoVerify = '$baseUrl/shurjopay/verify/';
  static const shurjoStatus = '$baseUrl/shurjopay/status/';
  static const shurjoReturn = '$baseUrl/shurjopay/return/';
  static const shurjoCancel = '$baseUrl/shurjopay/cancel/';

  //Users
  static const String users = "$baseUrl/users/${"id"}";

}
