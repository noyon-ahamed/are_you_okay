const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const initializeFirebase = () => {
    try {
        // Check if already initialized
        if (admin.apps.length > 0) {
            console.log('✅ Firebase already initialized');
            return admin;
        }

        // Initialize with service account
        admin.initializeApp({
            credential: admin.credential.cert({
                projectId: process.env.FIREBASE_PROJECT_ID,
                privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
                clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
            }),
            storageBucket: `${process.env.FIREBASE_PROJECT_ID}.appspot.com`,
        });

        console.log('✅ Firebase Admin SDK initialized successfully');
        return admin;

    } catch (error) {
        console.error('❌ Firebase initialization error (Check .env):', error.message);
        // Do not throw error to allow server to start without Firebase
        return {
            auth: () => ({ verifyIdToken: () => Promise.reject('Firebase not initialized') }),
            messaging: () => ({ send: () => Promise.resolve(), sendMulticast: () => Promise.resolve() }),
            storage: () => ({ bucket: () => ({ file: () => ({ save: () => { }, delete: () => { } }) }) }),
        };
    }
};

// Initialize Firebase
const firebaseAdmin = initializeFirebase();

// Export useful services
module.exports = {
    admin: firebaseAdmin,
    auth: firebaseAdmin.auth(),
    storage: firebaseAdmin.storage(),
    messaging: firebaseAdmin.messaging(),

    // Helper functions
    verifyIdToken: async (token) => {
        try {
            if (!firebaseAdmin.auth) throw new Error('Firebase Auth not initialized');
            const decodedToken = await firebaseAdmin.auth().verifyIdToken(token);
            return decodedToken;
        } catch (error) {
            console.error('Token verification failed:', error.message);
            throw new Error('Invalid authentication token');
        }
    },

    // Send push notification
    sendNotification: async (token, notification, data = {}) => {
        try {
            const message = {
                notification: {
                    title: notification.title,
                    body: notification.body,
                    imageUrl: notification.imageUrl || undefined,
                },
                data,
                token,
                android: {
                    priority: 'high',
                    notification: {
                        sound: 'default',
                        channelId: 'default',
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            sound: 'default',
                            badge: 1,
                        },
                    },
                },
            };

            const response = await firebaseAdmin.messaging().send(message);
            console.log('✅ Notification sent:', response);
            return response;

        } catch (error) {
            console.error('❌ Notification send failed:', error.message);
            throw error;
        }
    },

    // Send notification to multiple devices
    sendMulticastNotification: async (tokens, notification, data = {}) => {
        try {
            const message = {
                notification: {
                    title: notification.title,
                    body: notification.body,
                    imageUrl: notification.imageUrl || undefined,
                },
                data,
                tokens, // Array of FCM tokens
                android: {
                    priority: 'high',
                },
            };

            const response = await firebaseAdmin.messaging().sendMulticast(message);
            console.log(`✅ Sent to ${response.successCount}/${tokens.length} devices`);

            if (response.failureCount > 0) {
                response.responses.forEach((resp, idx) => {
                    if (!resp.success) {
                        console.error(`Failed to send to token ${idx}:`, resp.error);
                    }
                });
            }

            return response;

        } catch (error) {
            console.error('❌ Multicast notification failed:', error.message);
            throw error;
        }
    },

    // Upload file to Firebase Storage
    uploadFile: async (fileBuffer, fileName, folder = 'uploads') => {
        try {
            const bucket = firebaseAdmin.storage().bucket();
            const file = bucket.file(`${folder}/${fileName}`);

            await file.save(fileBuffer, {
                metadata: {
                    contentType: 'auto',
                },
                public: true,
            });

            const publicUrl = `https://storage.googleapis.com/${bucket.name}/${file.name}`;
            console.log('✅ File uploaded:', publicUrl);

            return publicUrl;

        } catch (error) {
            console.error('❌ File upload failed:', error.message);
            throw error;
        }
    },

    // Delete file from Firebase Storage
    deleteFile: async (filePath) => {
        try {
            const bucket = firebaseAdmin.storage().bucket();
            await bucket.file(filePath).delete();
            console.log('✅ File deleted:', filePath);

        } catch (error) {
            console.error('❌ File deletion failed:', error.message);
            throw error;
        }
    },

    // Create custom token for user
    createCustomToken: async (uid, claims = {}) => {
        try {
            const customToken = await firebaseAdmin.auth().createCustomToken(uid, claims);
            return customToken;
        } catch (error) {
            console.error('❌ Custom token creation failed:', error.message);
            throw error;
        }
    },

    // Get user by UID
    getUserByUid: async (uid) => {
        try {
            const userRecord = await firebaseAdmin.auth().getUser(uid);
            return userRecord;
        } catch (error) {
            console.error('❌ Get user failed:', error.message);
            throw error;
        }
    },

    // Delete user
    deleteUser: async (uid) => {
        try {
            await firebaseAdmin.auth().deleteUser(uid);
            console.log('✅ User deleted from Firebase:', uid);
        } catch (error) {
            console.error('❌ User deletion failed:', error.message);
            throw error;
        }
    },
};