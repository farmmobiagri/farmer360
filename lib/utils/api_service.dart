import 'dart:convert';

import 'package:farmer360/main_screen.dart';
import 'package:farmer360/otp.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../login.dart';
import '../urls.dart';
import 'alert_dialog.dart';

class ApiService {
  static String useCase = "Agri Promoter";

  static Future<void> loginUser(BuildContext context, SharedPreferences prefs, body) async {
    try {
      var response = await http.post(Uri.parse(Url.authUrl), body: body);
      if (response.statusCode == 200) {
        Map body = jsonDecode(response.body);
        ApiService.useCase = body["useCase"];

        // final prefs = await SharedPreferences.getInstance();
        // prefs.setString("useCase", useCase);

        if(context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => OtpPage(
                  loginResponse: body, prefs: prefs,
                )),
          );
        }
      } else {
        if(context.mounted) {
          handleResponse(context, response);
        }
      }
    } catch (e) {
      if(context.mounted) {
        alertMessage(context, e.toString());
      }
    }
  }



  static Future<void> handleResponse(context, response) async {
    if (response.statusCode == 403) {
      final prefs = await SharedPreferences.getInstance();

      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => LoginPage(
                prefs: prefs,
              )),
              (Route<dynamic> route) => false);
    } else {
      alertMessage(context, response.body);
    }
  }

  static Future<void> verifyOtp(context, SharedPreferences prefs, Map<String, dynamic> body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      body["useCase"] = useCase;
      var response = await http.put(Uri.parse(Url.authUrl), body: body);

      if (response.statusCode == 200) {
        dynamic responseJson = utf8.decode(response.bodyBytes);
        debugPrint(responseJson);

        Map<String, dynamic> data = jsonDecode(responseJson);
        if (data["userId"] != null) {
          prefs.setString("userId", data["userId"].toString());
          prefs.setString("userData", jsonEncode(data));

          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => MainScreen(
                    prefs: prefs,
                  )), (route) => false,);
        }
      } else {
        handleResponse(context, response);
      }
    } catch (e) {
      alertMessage(context, e.toString());
    }
  }


  static Future resendOtp(context, body) async {
    try {
      String id = body["id"].toString();
      String url = Url.resendOtp;
      var response = await http.post(
        Uri.parse(url),
        body: {"id": id},
      );
      if (response.statusCode == 200) {
        body = jsonDecode(response.body);
      } else {
        handleResponse(context, response);
      }
    } catch (e) {
      alertMessage(context, e.toString());
    }
    return body;
  }


  static getMultiAppUsers(BuildContext context, String userId) async {
    try {
      // http://192.168.1.48:8000/api/getMultiAppUsers/?userId=6
      String url = "${Url.getMultiAppUsers}?userId=$userId";
      var response = await http.get(
        Uri.parse(url),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        if(context.mounted) {
          handleResponse(context, response);
        }
      }
    } catch (e) {
      if(context.mounted) {
        alertMessage(context, e.toString());
      }
    }
  }

}