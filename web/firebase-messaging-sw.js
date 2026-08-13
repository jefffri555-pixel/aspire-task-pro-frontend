importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

const firebaseConfig = {
  apiKey: "AIzaSyBZlF_M-KjntXHlAfHyjIaiDO4gU8jWYPg",
  appId: "1:462653983121:web:0f0d86e34690afca4c7230",
  messagingSenderId: "462653983121",
  projectId: "aspire-cb886",
  authDomain: "aspire-cb886.firebaseapp.com",
  storageBucket: "aspire-cb886.firebasestorage.app",
  measurementId: "G-J8691FZ3ZD"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const notificationTitle = payload.notification?.title || 'New Notification';
  const notificationOptions = {
    body: payload.notification?.body,
    icon: '/favicon.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
