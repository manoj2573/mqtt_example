import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_controller.dart';
import 'motor_control_screen.dart';
import 'mqtt_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? registrationNumber;

  @override
  void initState() {
    super.initState();
    _checkRegistrationNumber();
  }

  Future<void> _checkRegistrationNumber() async {
    String? uid = auth.currentUser?.uid;
    if (uid == null) return;

    DocumentSnapshot userDoc =
        await firestore.collection("users").doc(uid).get();

    setState(() {
      registrationNumber = userDoc["registrationNumber"];
    });

    if (registrationNumber == null || registrationNumber!.isEmpty) {
      _showRegistrationDialog();
    } else {
      MqttService.subscribeToTopic("$registrationNumber/mobile");
    }
  }

  void _showRegistrationDialog() {
    TextEditingController regController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text("Enter Registration Number"),
        content: TextField(
          controller: regController,
          decoration: InputDecoration(labelText: "Registration Number"),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              String regNum = regController.text.trim();
              if (regNum.isNotEmpty) {
                String? uid = auth.currentUser?.uid;
                if (uid != null) {
                  await firestore.collection("users").doc(uid).update({
                    "registrationNumber": regNum,
                  });

                  setState(() {
                    registrationNumber = regNum;
                  });

                  MqttService.subscribeToTopic("$registrationNumber/mobile");
                  Get.back();
                }
              } else {
                Get.snackbar("Error", "Please enter a valid number");
              }
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  void sendStatusRequest() {
    if (registrationNumber != null && registrationNumber!.isNotEmpty) {
      MqttService.publishStatusRequest(registrationNumber!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status request sent!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Motor Control"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: sendStatusRequest, // ✅ Refresh to check status
            tooltip: "Refresh Status",
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                "Menu",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text("Logout"),
              onTap: () {
                Get.find<AuthController>().logout();
                Navigator.pop(context); // Close the drawer
              },
            ),
          ],
        ),
      ),
      body: registrationNumber == null || registrationNumber!.isEmpty
          ? Center(child: Text("No device added"))
          : MotorControlScreen(registrationNumber: registrationNumber!),
    );
  }
}
