import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'login_page.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Rx<User?> firebaseUser = Rx<User?>(null);

  @override
  void onInit() {
    super.onInit();
    firebaseUser.bindStream(_auth.authStateChanges());
  }

  void register(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      _firestore.collection('users').doc(userCredential.user!.uid).set({
        "email": email,
        "registrationNumber": "",
      });
      Get.offAll(() => HomeScreen());
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  void login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      Get.offAll(() => HomeScreen());
    } catch (e) {
      Get.snackbar("Login Failed", e.toString());
    }
  }

  void logout() async {
    await _auth.signOut();
    Get.offAll(() => LoginPage());
  }

  void resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Get.snackbar("Success", "Password reset email sent!");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }
}
