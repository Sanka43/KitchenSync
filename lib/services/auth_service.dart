import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register a new user and store additional details in Firestore
  Future<String?> registerUser({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      print("⏳ Creating Firebase user...");
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("✅ Firebase user created!");

      User? user = result.user;

      if (user != null) {
        print("📝 Writing to Firestore...");
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'username': username,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print("✅ Firestore write successful!");
        return null;
      } else {
        print("❌ Firebase user is null.");
        return "User creation failed.";
      }
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.message}");
      return e.message;
    } catch (e) {
      print("❌ General exception: $e");
      return "An unexpected error occurred: $e";
    }
  }

  // Login user and retrieve their role from Firestore
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      print("🔐 Signing in user...");
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        print("📄 Retrieving user data from Firestore...");
        DocumentSnapshot snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (snapshot.exists && snapshot.data() != null) {
          String role = snapshot.get('role');
          print("✅ Login successful. Role: $role");
          return {'success': true, 'role': role};
        } else {
          return {
            'success': false,
            'error': 'User data not found in Firestore.',
          };
        }
      } else {
        return {'success': false, 'error': 'Authentication failed.'};
      }
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.message}");
      return {'success': false, 'error': e.message};
    } catch (e) {
      print("❌ General exception: $e");
      return {'success': false, 'error': 'An unexpected error occurred: $e'};
    }
  }

  // Get current logged in user's UID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Get current logged in user's role from Firestore
  Future<String?> getCurrentUserRole() async {
    try {
      String? uid = getCurrentUserId();
      if (uid == null) return null;

      DocumentSnapshot snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.get('role');
      } else {
        return null;
      }
    } catch (e) {
      print("❌ Error fetching role: $e");
      return null;
    }
  }

  // Sign out the user
  Future<void> logout() async {
    print("🚪 Signing out...");
    await _auth.signOut();
    print("✅ Signed out successfully.");
  }
}
