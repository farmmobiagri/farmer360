import 'package:farmer360/urls.dart';
import 'package:farmer360/utils/alert_dialog.dart';
import 'package:farmer360/utils/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LoginPage extends StatefulWidget {
  final SharedPreferences prefs;

  const LoginPage({super.key, required this.prefs});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isObscure = true;
  bool isApiCalled = false;
  TextEditingController organizationController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    if (Url.baseUrl == "http://192.168.1.51:8000/api") {
      organizationController.text = "1";
      emailController.text = "dhiraj";
      passwordController.text = "Admin@2023";

      // emailController.text = "swapnil";
      // passwordController.text = "Admin@2023";

      // emailController.text = "akmangade";
      // passwordController.text = "Admin@2023";
    }
    super.initState();
  }

  @override
  void dispose() {
    organizationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 50,
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sign In",
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  "Enter your user name and password for signing in.",
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  "User Name",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    focusColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    hintText: "Enter User Name",
                  ),
                ),
                const SizedBox(
                  height: 15,
                ),
                Text(
                  "Password",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  controller: passwordController,
                  obscureText: isObscure,
                  decoration: InputDecoration(
                      focusColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      hintText: "Enter password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            isObscure = !isObscure;
                          });
                        },
                      )),
                ),
                const SizedBox(
                  height: 40,
                ),
                SizedBox(
                  width: double.infinity,
                  child: Stack(
                    children: [
                      if (isApiCalled) ...[
                        const Center(child: CircularProgressIndicator())
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: MaterialButton(
                            onLongPress: () {
                              if (Url.baseUrl ==
                                  "http://192.168.1.47:8000/api") {
                                TextEditingController controller =
                                    TextEditingController(text: Url.baseUrl);
                                showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                          title: Text("Base Url"),
                                          content: TextFormField(
                                            controller: controller,
                                          ),
                                          actions: [
                                            MaterialButton(
                                                onPressed: () {
                                                  Url.baseUrl = controller.text;
                                                  Navigator.pop(context);
                                                },
                                                child: Text("Save"))
                                          ],
                                        ));
                              }
                            },
                            onPressed: () async {
                              // if (organizationController.text.isEmpty) {
                              //   alertMessage(
                              //       context, "Please enter Organization");
                              // } else
                              if (emailController.text.isEmpty) {
                                alertMessage(context, "Please enter Email");
                              } else if (passwordController.text.isEmpty) {
                                alertMessage(context, "Please enter Password");
                              } else {
                                setState(() {
                                  isApiCalled = true;
                                });

                                await ApiService.loginUser(context, widget.prefs, {
                                  "otp": organizationController.text,
                                  "userName": emailController.text,
                                  "password": passwordController.text
                                });

                                setState(() {
                                  isApiCalled = false;
                                });
                              }
                            },
                            // minWidth: 100.0,
                            height: 50,
                            color: Colors.green,
                            child: Text("Next",
                                style: const TextStyle(
                                    fontSize: 16.0, color: Colors.white)),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 50,
        child: GestureDetector(
          onLongPress: () {
            alertMessage(context, Url.baseUrl);
          },
          child: const Column(
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
      ),
    );
  }
}
