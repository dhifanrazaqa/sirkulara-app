import 'package:flutter/material.dart';

class SetupFirebaseScreen extends StatelessWidget {
  const SetupFirebaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.cloud_off_outlined, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Firebase belum dikonfigurasi',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'App ini membaca kredensial Firebase dari dart-define agar tidak memakai API key demo.',
              ),
              const SizedBox(height: 24),
              const Text(
                'Jalankan app dengan parameter berikut:',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const SelectableText(
                'flutter run\n'
                '  --dart-define=FIREBASE_API_KEY=...\n'
                '  --dart-define=FIREBASE_APP_ID=...\n'
                '  --dart-define=FIREBASE_MESSAGING_SENDER_ID=...\n'
                '  --dart-define=FIREBASE_PROJECT_ID=...\n'
                '  --dart-define=FIREBASE_STORAGE_BUCKET=...',
              ),
              const SizedBox(height: 24),
              const Text(
                'Atau generate file resmi dengan FlutterFire CLI setelah login ke Firebase Console.',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {},
                child: const Text('Isi konfigurasi lalu jalankan ulang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
