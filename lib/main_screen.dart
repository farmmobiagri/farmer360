import 'dart:convert';
import 'dart:io';

import 'package:agripromoter/main.dart' as agripromoter;
import 'package:android_intent_plus/android_intent.dart';
import 'package:farmer360/login.dart';
import 'package:farmer360/utils/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:ota_update/ota_update.dart';
import 'package:procurement/app.dart' as procurementApp;
import 'package:procurement/flavors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:version/version.dart'; // add

class MainScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const MainScreen({super.key, required this.prefs});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<Map<String, dynamic>> _seedApps = [];
  List<Map<String, dynamic>> appList = [];

  bool loading = true;
  int? installingIndex;
  String? installStatus;
  String userName = "";
  String selectedApp = "";

  @override
  void initState() {
    super.initState();

    F.appFlavor = Flavor.procurement;

    getApps();
  }

  Future<void> getApps({bool? loading}) async {
    try {
      if (loading == true) {
        setState(() {
          this.loading = true;
        });
      }
      String userData = widget.prefs.getString("userData") ?? "";

      if (userData.isNotEmpty) {
        Map<String, dynamic> data = jsonDecode(userData);
        // print();

        userName = data["employeeName"] ?? "";
      }

      final response = await ApiService.getMultiAppUsers(context, widget.prefs.getString("userId") ?? "");

      if (response != null && response is List) {
        _seedApps = List<Map<String, dynamic>>.from(response);

        final List<AppInfo> installed = await InstalledApps.getInstalledApps(true, true);

        final Map<String, AppInfo> byName = {for (final app in installed) app.name.toLowerCase(): app};

        final merged = _seedApps.map((seed) {
          final String seedName = (seed["appName"] as String? ?? "").trim();
          final String lookup = seedName.toLowerCase();
          final AppInfo? match = byName[lookup];

          return {...seed, "appName": seedName, "versionName": match?.versionName ?? "", "packageName": match?.packageName ?? "", "icon": match?.icon};
        }).toList();

        if (mounted) {
          setState(() {
            appList = merged;
            this.loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            appList = [];
            this.loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          appList = _seedApps.map((e) => {...e, "versionName": "", "packageName": "", "icon": null}).toList();
          this.loading = false;
        });
      }
    }
  }

  Version? _parseVersion(String? v) {
    if (v == null) return null;
    final s = v.trim();
    if (s.isEmpty) return null;
    try {
      final cleaned = (s.startsWith('v') || s.startsWith('V')) ? s.substring(1) : s;
      final normalized = cleaned.split('+').first.split('(').first.trim();
      return Version.parse(normalized);
    } catch (_) {
      return null;
    }
  }

  Future<void> _copyLoginPayload({required String baseUrl, required String token}) async {
    final payload = {"type": "login", "baseUrl": baseUrl, "token": token, "ts": DateTime.now().toIso8601String()};
    await Clipboard.setData(ClipboardData(text: jsonEncode(payload)));
  }

  Future<void> _downloadAndInstallApk(int index) async {
    final item = appList[index];
    final String downloadUrl = item["downloadUrl"] as String? ?? "";
    final String apkFilePath = item["apkFilePath"] as String? ?? "";
    final String url = "$downloadUrl$apkFilePath";

    // Pre-copy payload before starting download
    final String userName = item["userName"] ?? "";
    final String token = item["Token"] ?? item["token"] ?? "";
    final String baseUrl = item["baseUrl"] ?? "";

    await _copyLoginPayload(baseUrl: baseUrl, token: token);

    setState(() {
      installingIndex = index;
      installStatus = "Starting download…";
    });

    try {
      await for (final ev in OtaUpdate().execute(url, destinationFilename: "${item['appName']}.apk")) {
        if (!mounted) break;

        setState(() {
          installStatus = "${ev.status} ${ev.value ?? ''}";
        });

        final s = ev.status.toString().toLowerCase();
        if (s.contains('error') || s.contains('failed') || s.contains('cancel')) {
          if (!mounted) break;
          setState(() {
            installingIndex = null;
          });
          break;
        }
      }

      await getApps();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        installStatus = "Install failed: $e";
        installingIndex = null;
      });
    } finally {
      if (!mounted) return;
      if (installingIndex == index) {
        setState(() {
          installingIndex = null;
        });
      }
    }
  }

  Future<void> _launchWithCredentials({required String packageName, required String userName, required String token, Map<String, String>? deepLinkParts}) async {
    if (!Platform.isAndroid) return;

    try {
      // Clipboard is already set in handlers before this is called
      final ok = await InstalledApps.startApp(packageName);
      if (ok == true) return;

      final intent = AndroidIntent(action: 'action_main', category: 'category_launcher', package: packageName, flags: <int>[268435456, 32768, 524288]);
      await intent.launch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot open target app. Please install or update it.")));
    }
  }

  Future<void> _handleTap(int index) async {
    final item = appList[index];
    final String userName = item["userName"] ?? "";
    final String token = item["Token"] ?? item["token"] ?? "";
    String packageName = (item["packageName"] as String?)?.trim() ?? "";
    String baseUrl = (item["baseUrl"] as String?)?.trim() ?? "";
    final Map<String, String>? deeplink = (item["deeplink"] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString()));

    // Always set clipboard payload on tap, before branching
    await _copyLoginPayload(baseUrl: baseUrl, token: token);

    if (packageName.isEmpty) {
      await _downloadAndInstallApk(index);

      final updated = appList[index];
      final String newPkg = (updated["packageName"] as String?)?.trim() ?? "";
      if (newPkg.isNotEmpty) {
        await _launchWithCredentials(packageName: newPkg, userName: userName, deepLinkParts: deeplink, token: token);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Install did not complete. Try again.")));
        }
      }
      return;
    }

    await _launchWithCredentials(packageName: packageName, userName: userName, token: token, deepLinkParts: deeplink);
  }

  Widget _statusChip({required bool installed, required bool hasUpdate}) {
    if (!installed) {
      return Chip(
        label: const Text("Install"),
        backgroundColor: Colors.red.shade50,
        labelStyle: const TextStyle(color: Colors.redAccent),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }
    if (hasUpdate) {
      return Chip(
        label: const Text("Update"),
        backgroundColor: Colors.blue.shade50,
        labelStyle: const TextStyle(color: Colors.blue),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    }
    return Chip(
      label: const Text("Installed"),
      backgroundColor: Colors.green.shade50,
      labelStyle: const TextStyle(color: Colors.green),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/leaf.jpeg"), // Your image path
          fit: BoxFit.cover, // Adjust how the image fits the container
        ),
      ),
      child: Scaffold(
          backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white54,
          title: InkWell(
            onTap: () async {
              if(selectedApp.isNotEmpty) {
                String userId = widget.prefs.getString("userId") ?? "";
                String userData = widget.prefs.getString("userData") ?? "";

                await widget.prefs.clear();
                selectedApp = "";
                await widget.prefs.setString("userId", userId);
                await widget.prefs.setString("userData", userData);
                setState(() {});
              }
            },
            child: Image.asset("assets/golden_agri_inputs.png", height: 50),
          ),
          actions: [
            if (selectedApp.isEmpty) ...[
              TextButton(
                onPressed: () async {
                  if (selectedApp.isEmpty) {
                    await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Are you sure wants to logout?"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text("Close"),
                          ),
                          MaterialButton(
                            onPressed: () async {
                              await widget.prefs.clear();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginPage(prefs: widget.prefs)), (route) => false);
                              }
                            },
                            child: Text("Logout"),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: Icon(selectedApp.isEmpty ? Icons.logout : Icons.home),
              ),
            ],
          ],
        ),
        body: selectedApp.isNotEmpty
            ? selectedApp == "FMAN" || selectedApp == "Seed Production"
            ? procurementApp.App()
            : agripromoter.MyApp(isShowLogout: false,)
            : loading
            ? const Center(child: CircularProgressIndicator())
            : appList.isNotEmpty
            ? false
            ? Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: MaterialButton(
                onPressed: () {
                  setState(() {
                    selectedApp = "Procurement";
                  });
                },
                child: Text("Procurement"),
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: MaterialButton(
                onPressed: () {
                  setState(() {
                    selectedApp = "Procurement";
                  });
                },
                child: Text("Procurement"),
              ),
            ),

            Divider(),
            SizedBox(
              width: double.infinity,
              child: MaterialButton(
                onPressed: () {
                  setState(() {
                    selectedApp = "Agri Promoter";
                  });
                },
                child: Text("Agri Promoter"),
              ),
            ),
          ],
        )
            : Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.white60,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text("User name: $userName", softWrap: true, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: appList.length,
                    itemBuilder: (context, index) {
                      final item = appList[index];
                      final Uint8List? iconBytes = item["icon"] as Uint8List?;
                      final String title = item["appName"] as String? ?? "";
                      final String apiVersion = (item["apkVersion"] as String? ?? "").trim();
                      final String versionName = (item["versionName"] as String? ?? "").trim();
                      final String packageName = (item["packageName"] as String? ?? "").trim();
                      final bool isInstalling = installingIndex == index;

                      final Version? latest = _parseVersion(apiVersion);
                      final Version? installed = _parseVersion(versionName);

                      // Correct hasUpdate: only if both parse and latest > installed
                      final bool hasUpdate = (latest != null && installed != null && latest > installed);

                      final bool isInstalled = packageName.isNotEmpty;

                      String subtitleText = "";
                      Color subtitleColor = Colors.black54;

                      if (isInstalling) {
                        subtitleText = installStatus ?? "Installing…";
                        subtitleText = subtitleText.replaceAll("OtaStatus.", "");
                        subtitleColor = Colors.orange;
                      } else if (isInstalled) {
                        if (hasUpdate) {
                          // subtitleText = "Installed: $versionName  •  Latest: $apiVersion";
                          subtitleColor = Colors.blueAccent;
                        } else {
                          subtitleText = versionName.isNotEmpty ? "v$versionName" : "Installed";
                          subtitleColor = Colors.black54;
                        }
                      } else {
                        // subtitleText = apiVersion.isNotEmpty ? "Latest: $apiVersion" : "Not installed";
                        // subtitleColor = Colors.redAccent;
                      }

                      return Card(
                        color: Colors.white54,
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: GestureDetector(
                            onTap: true
                                ? () async {
                              final item = appList[index];
                              final String userName = item["userName"] ?? "";
                              final String token = item["Token"] ?? item["token"] ?? "";
                              String packageName = (item["packageName"] as String?)?.trim() ?? "";
                              String baseUrl = (item["baseUrl"] as String?)?.trim() ?? "";
                              final Map<String, String>? deeplink = (item["deeplink"] as Map?)?.map((k, v) => MapEntry(k.toString(), v.toString()));

                              // Always set clipboard payload on tap, before branching
                              await _copyLoginPayload(baseUrl: baseUrl, token: token);

                              setState(() {
                                if (title == "FMAN") {
                                  F.appFlavor = Flavor.procurement;
                                } else if (title == "Seed Production") {
                                  F.appFlavor = Flavor.seedproduction;
                                }
                                selectedApp = title;
                              });
                            }
                                : isInstalling
                                ? null
                                : () {
                              if (isInstalled && !hasUpdate) {
                                _handleTap(index);
                              } else if (!isInstalled) {
                                _downloadAndInstallApk(index);
                              }
                              // If update is available, prefer explicit Update button
                            },
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // if (iconBytes != null && iconBytes.isNotEmpty) ...[
                                    // ],

                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset("assets/ic_launcher.png", width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.apps, size: 56)),
                                    ),

                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              // leading: iconBytes != null && iconBytes.isNotEmpty
                              //     ? ClipRRect(
                              //         borderRadius: BorderRadius.circular(8),
                              //         child: Image.memory(iconBytes, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.apps, size: 56)),
                              //       )
                              //     : const Icon(Icons.apps, size: 48),
                              // title: Row(
                              //   children: [
                              //     Expanded(
                              //       child: Text(
                              //         title,
                              //         style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              //         maxLines: 1,
                              //         overflow: TextOverflow.ellipsis,
                              //       ),
                              //     ), // const SizedBox(width: 8),
                              //     // _statusChip(installed: isInstalled, hasUpdate: hasUpdate),
                              //   ],
                              // ),
                              // subtitle: Text(subtitleText, style: TextStyle(color: subtitleColor)),
                              // trailing: true
                              //     ? null
                              //     : isInstalling
                              //     ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                              //     : Row(
                              //         mainAxisSize: MainAxisSize.min,
                              //         children: [
                              //           if (!isInstalled) IconButton(icon: const Icon(Icons.download), tooltip: "Install", onPressed: () => _downloadAndInstallApk(index), color: Colors.redAccent),
                              //           if (isInstalled && hasUpdate) IconButton(icon: const Icon(Icons.system_update), tooltip: "Update", onPressed: () => _downloadAndInstallApk(index), color: Colors.blue),
                              //           if (isInstalled) IconButton(icon: const Icon(Icons.open_in_new), tooltip: "Open", onPressed: () => _handleTap(index)),
                              //         ],
                              //       ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Padding(padding: const EdgeInsets.only(left: 32.0, right: 32, bottom: 16), child: Column(
                  children: [
                    // Image.asset("assets/fman1.png", width: 170, height: 90,),
                    Text("Powered by FarmMobi", style: TextStyle(color: Colors.white),)
                  ],
                )),
              ],
            ),
          ],
        )
            : Center(
          child: TextButton(onPressed: () => getApps(loading: true), child: const Text("Retry")),
        ),
      ),
    );
  }
}
