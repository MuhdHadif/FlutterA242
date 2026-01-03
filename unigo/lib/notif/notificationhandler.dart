import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';

class NotificationHandler {
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  Future<void> addUser(String id, String token){
    return users.doc(id).set({
      'token': token,
    })
    // ignore: invalid_return_type_for_catch_error
    .catchError((error) => log("Failed to add user: $error"));
  }

  // Future<String?> getUserToken(String userId) async {
  //   DocumentSnapshot doc = await users.doc(userId).get();

  //   if (doc.exists) {
  //     return doc['token'] as String;
  //   }
  //   return null;
  // }

  Future<void> sendPushNotification(String receiverId, String title, String body) async {
    log("Receiver ID: $receiverId");

    final doc = await users.doc(receiverId).get();
    if (!doc.exists) {
      log("User document does not exist");
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    final String? token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      log("FCM token is null or empty — aborting");
      return;
    }

    log("Token: $token");

    final callable = FirebaseFunctions.instance.httpsCallable('sendPushToUser');

    log("Calling cloud func");
    await callable.call({
      'token': token,
      'title': title,
      'body': body,
    });
  }
}