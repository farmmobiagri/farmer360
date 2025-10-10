import 'package:farmer360/utils/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/alert_dialog.dart';

class OtpPage extends StatefulWidget {
  final Map loginResponse;
  final SharedPreferences prefs;

  const OtpPage({super.key, required this.loginResponse, required this.prefs});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  TextEditingController otpController = TextEditingController();
  bool isApiCalled = false;
  bool isResendCalled = false;
  Map loginResponse = {};

  bool isDebugApp = true;

  @override
  void initState() {
    loginResponse = widget.loginResponse;
    if (isDebugApp) {
      if (loginResponse['otp'] != null) {
        otpController.text = loginResponse['otp'].toString();
        submitOtp();
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: const SizedBox(
          height: 50,
          child: Column(
            children: [
              Text("Contract Farming",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                "Powered By Farmmobi",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              )
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
                left: 24.0, right: 24.0, top: 50, bottom: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  "OTP",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  "Please enter the otp sent to your email address.",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey),
                ),
                const SizedBox(
                  height: 30,
                ),
                const Text(
                  "OTP",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  controller: otpController,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  decoration: InputDecoration(
                    counter: Container(),
                    focusColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    hintText: "Enter OTP",
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                const Center(
                  child: Text(
                    "Don't receive an OTP?",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      // fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                  width: 10,
                ),
                Center(
                  child: InkWell(
                    onTap: () async {
                      setState(() {
                        isResendCalled = true;
                      });
                      loginResponse =
                          await ApiService.resendOtp(context, loginResponse);
                      if (isDebugApp) {
                        if (loginResponse['otp'] != null) {
                          otpController.text = loginResponse['otp'].toString();
                        }
                      }
                      setState(() {
                        isResendCalled = false;
                      });
                    },
                    child: Stack(
                      children: [
                        if (isResendCalled) ...[
                          const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator())
                        ] else ...[
                          const Text(
                            "Resend OTP ",
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Stack(
                  children: [
                    if (isApiCalled) ...[
                      const Center(child: CircularProgressIndicator())
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: MaterialButton(
                          onPressed: () async {
                            // {"email": "", "otp": "","id":""}
                            submitOtp();
                          },
                          height: 50,
                          color: Colors.green,
                          child: const Text('Submit',
                              style: TextStyle(
                                  fontSize: 16.0, color: Colors.white)),
                        ),
                      )
                    ],
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  submitOtp() async {
    if (otpController.text.isEmpty) {
      alertMessage(context, "Please enter OTP");
    } else {
      setState(() {
        isApiCalled = true;
      });

      await ApiService.verifyOtp(context,widget.prefs, {
        "email": loginResponse["email"].toString(),
        "otp": otpController.text,
        "id": loginResponse["id"].toString()
      });

      setState(() {
        isApiCalled = false;
      });
    }
  }
}
