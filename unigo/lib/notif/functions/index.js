const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendPushToUser = functions.https.onCall(async (data, context) => {
  console.log("🔥 FUNCTION HIT");
  console.log("🔥 RAW DATA:", data.data);
  const {token, title, body}= data.data;

  if (!token) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "FCM token is required",
    );
  }

  const message = {
    token,
    notification: {
      title: title || "Notification",
      body: body || "You have a new message",
    },
  };

  try {
    const response = await admin.messaging().send(message);
    return {success: true, response};
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});
