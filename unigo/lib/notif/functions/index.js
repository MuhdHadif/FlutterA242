const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendPushToUser = functions.https.onCall(async (payload, context) => {
  console.log("🔥 RAW DATA:", payload.data);

  let {tokens, title, body, data} = payload.data;

  // If only 1 token - Normalize tokens to an array
  if (typeof tokens === "string") {
    tokens = [tokens];
  }

  if (!Array.isArray(tokens) || tokens.length === 0) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "A token or a non-empty array of FCM tokens is required",
    );
  }

  const message = {
    tokens,
    notification: {
      title: title || "Notification",
      body: body || "You have a new message",
    },
    data: {
      screen: data.screen,
    },
  };

  console.log("🔥 RAW MESSAGE:", message);

  try {
    const response = await admin.messaging().sendEachForMulticast(message);

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
      responses: response.responses,
    };
  } catch (error) {
    throw new functions.https.HttpsError("internal", error.message);
  }
});
