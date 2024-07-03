import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:provider/provider.dart';

import 'dialogs/show_auth_error.dart';
import 'firebase_options.dart';
import 'loading/loading_screen.dart';
import 'provider/auth_provider.dart';
import 'provider/reminders_provider.dart';
import 'state/app_state.dart';
import 'views/login_view.dart';
import 'views/register_view.dart';
import 'views/reminders_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    Provider(
      create: (context) => AppState(
        authProvider: FirebaseAuthProvider(),
        remindersProvider: FirestoreRemindersProvider(),
      )..initialize(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ReactionBuilder(
        builder: (context) {
          return autorun(
            (_) {
              // Handle Loading Screen
              final isLoading = context.read<AppState>().isLoading;
              if (isLoading) {
                LoadingScreen.instance()
                    .show(context: context, text: 'Loading...');
              } else {
                LoadingScreen.instance().hide();
              }

              // Handle Auth Error
              final authError = context.read<AppState>().authError;
              if (authError != null) {
                showAuthError(
                  authError: authError,
                  context: context,
                );
              }
            },
          );
        },
        child: Observer(
          name: 'CurrentScreen',
          builder: (context) {
            switch (context.read<AppState>().currentScreen) {
              case AppScreen.login:
                return LoginView();
              case AppScreen.register:
                return RegisterView();
              case AppScreen.reminders:
                return const RemindersView();
            }
          },
        ),
      ),
    );
  }
}
