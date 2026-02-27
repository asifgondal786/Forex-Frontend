// Firebase configuration for web platform
// This initializes Firebase services when the app loads on web

const firebaseConfig = {
  apiKey: "AIzaSyAGPIvZvdbyrXwRJonYmSZvUHhGEmapec8",
  authDomain: "forexcompanion-e5a28.firebaseapp.com",
  databaseURL: "https://forexcompanion-e5a28-default-rtdb.firebaseio.com",
  projectId: "forexcompanion-e5a28",
  storageBucket: "forexcompanion-e5a28.firebasestorage.app",
  messagingSenderId: "238745148522",
  appId: "1:238745148522:web:91d07c07f4edf09026be13",
  measurementId: "G-F24QVTGL77"
};

// Initialize Firebase
if (typeof firebase !== 'undefined') {
  firebase.initializeApp(firebaseConfig);
  
  // Enable persistence for offline support
  firebase.firestore().enablePersistence()
    .then(() => {
      console.log('✓ Firestore persistence enabled');
    })
    .catch((err) => {
      if (err.code === 'failed-precondition') {
        console.warn('Multiple tabs open, persistence disabled');
      } else if (err.code === 'unimplemented') {
        console.warn('Browser does not support persistence');
      }
    });

  // Log Firebase initialization status
  console.log('✓ Firebase initialized with config:', {
    projectId: firebaseConfig.projectId,
    authDomain: firebaseConfig.authDomain,
    databaseURL: firebaseConfig.databaseURL,
    storageBucket: firebaseConfig.storageBucket,
  });
}
