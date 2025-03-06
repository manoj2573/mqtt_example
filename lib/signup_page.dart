import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';

class SignupPage extends StatelessWidget {
  final AuthController authController = Get.find();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                authController.register(emailController.text.trim(),
                    passwordController.text.trim());
              },
              child: Text("Sign Up"),
            ),
            TextButton(
              onPressed: () => Get.toNamed('/login'),
              child: Text("Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}
