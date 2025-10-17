class Url {
 // static String baseUrl = "http://192.168.1.51:8000/api";
 //  static String baseUrl = "http://13.203.210.229:8000/api";

  //http://13.200.231.209:8000
  static String baseUrl = "http://13.200.231.209:8000/api";
  // http://127.0.0.1:8000/api/tokenNew/?userId=90
  // https://teams.microsoft.com/l/message/19:meeting_YzM4Yzc2NTYtMjBkMy00MzRhLTg3YzktYzBkNTg4OGRhMTI0@thread.v2/1756353615565?context=%7B%22contextType%22%3A%22chat%22%7D
  // static String baseUrl = "http://3.110.154.53:8000/api/";
  // static String baseUrl = "http://192.168.1.51:8000/api";
  static String authUrl = "$baseUrl/token/";
  static String tokenNew = "$baseUrl/tokenNew/";
  static String getMultiAppUsers = "$baseUrl/getMultiAppUsers/";

  static String agriPromoter = "$baseUrl/agriPromoter/";
  static String agriPromoterFarmer = "$baseUrl/agriPromoterFarmer/";
  static String agriPromoterDashboard = "$baseUrl/agriPromoterDashboard/";
  static String fieldDetail = "$baseUrl/fieldDetail/";
  static String trainingMov = "$baseUrl/trainingMov/";
  static String marketIntelligenceGathering =
      "$baseUrl/marketIntelligenceGathering/";
  static String getMaster = "$baseUrl/getAgriPromoterMaster/";
  static String resendOtp = "$baseUrl/resendOtp/";
  static String agriFarmInspection = "$baseUrl/agriFarmInspection/";
  static String agriCropCutDetail = "$baseUrl/agriCropCutDetail/";
  static String hubSales = "$baseUrl/hubSales/";

  static String downloadUrl =
      "https://farmmobi-img-dev.s3.ap-south-1.amazonaws.com/";
  static String mobileServicePermissionList =
      "$baseUrl/mobileServicePermissionList/";
  static String goodsIssue = "$baseUrl/goodsIssue/";
  static String hubInventory = "$baseUrl/hubInventory/";
}
