// src/firebase.js
import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";
import { getStorage } from "firebase/storage";

const firebaseConfig = {
  android: {
    apiKey: "AIzaSyBnpJqjDQ9h8NfzspmhwKzC9z3X4eY9uYY",
    authDomain: "lockify.co.in",
    projectId: "zipind-57",
    messagingSenderId: "676005468146",
    storageBucket: "zipind-57.firebasestorage.app",
    appId: "1:676005468146:android:0d2cf99ed8b80f8e40fd6b",
  },
  ios: {
    apiKey: "AIzaSyBnpJqjDQ9h8NfzspmhwKzC9z3X4eY9uYY",
    authDomain: "lockify.co.in",
    projectId: "zipind-57",
    messagingSenderId: "676005468146",
    storageBucket: "zipind-57.firebasestorage.app",
    appId: "1:676005468146:ios:2e1a49e74843f79d40fd6b",
  },
};

const app = initializeApp(firebaseConfig.android);
    
export const db = getFirestore(app);
export const storage = getStorage(app);
export default app;
