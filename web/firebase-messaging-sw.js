importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'YOUR_FIREBASE_WEB_API_KEY',
  appId: '1:878238233412:web:9481143f5c790374df5d11',
  messagingSenderId: '878238233412',
  projectId: 'rally-c6299',
  authDomain: 'rally-c6299.firebaseapp.com',
  storageBucket: 'rally-c6299.firebasestorage.app',
});

firebase.messaging();
