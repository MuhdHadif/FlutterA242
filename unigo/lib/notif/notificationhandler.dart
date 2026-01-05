import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';

class NotificationHandler {
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  Future<void> addUser(String id) async {
    String? token = await FirebaseMessaging.instance.getToken();
    log("user TOKEN: $token");
    return users.doc(id).set({
      'token': token,
    })
    // ignore: invalid_return_type_for_catch_error
    .catchError((error) => log("Failed to add user: $error"));
  }

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

    log("Receiver Token: $token");

    final callable = FirebaseFunctions.instance.httpsCallable('sendPushToUser');

    log("Calling cloud func");
    await callable.call({
      'tokens': token,
      'title': title,
      'body': body,
      'data': {
        'screen': 'messagescreen',
        'click_action': 'FLUTTER_NOTIFICATION_CLICK'
      }
    });
  }

  Future<void> sendPushNotificationToAll(String title, String body) async {
    log("Sending push notification to all users");

    final querySnapshot = await users.get();

    List<String> tokens = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final String? token = data['token'];

      if (token != null && token.isNotEmpty) {
        tokens.add(token);
      }
    }

    if (tokens.isEmpty) {
      log("No FCM tokens found — aborting");
      return;
    }

    log("Total tokens found: ${tokens.length}");

    final callable =
        FirebaseFunctions.instance.httpsCallable('sendPushToUser');

    // Send in chunks of 500 (FCM limit)
    const int chunkSize = 500;
    for (var i = 0; i < tokens.length; i += chunkSize) {
      final chunk = tokens.sublist(
        i,
        i + chunkSize > tokens.length ? tokens.length : i + chunkSize,
      );

      await callable.call({
        'tokens': chunk,
        'title': title,
        'body': body,
        'data': {
          'screen': 'mainscreen',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK'
        }
      });
    }

    log("Push notification sent to all users");
  }
}