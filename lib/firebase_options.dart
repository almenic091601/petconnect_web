import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Default Firebase configuration options for the web app
class DefaultFirebaseOptions {
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCvRpPKVi9v-TqqzCZJePPc3pu5zX9xMoQ',
    appId: '1:605648135641:web:44a83f96fd3ca4613ee5c8',
    messagingSenderId: '605648135641',
    projectId: 'my-petconnect',
    authDomain: 'my-petconnect.firebaseapp.com',
    storageBucket: 'my-petconnect.firebasestorage.app',
  );

  static FirebaseOptions get currentPlatform => web;
}
