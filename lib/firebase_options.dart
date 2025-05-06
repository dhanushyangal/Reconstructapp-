import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Add your Firebase configuration here
    // You can get this from Firebase Console
    return const FirebaseOptions(
      apiKey: 'AIzaSyC6tPoN0mnnrsGVhsTpoqNJzm63MoDRksU',
      appId: '1:633982729642:android:5bc8eafe77d83923f93fd3',
      messagingSenderId: '633982729642',
      projectId: 'recostrect3',
    );
  }
}
