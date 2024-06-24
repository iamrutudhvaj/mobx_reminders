import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../extensions/if_debugging.dart';
import '../state/app_state.dart';

class RegisterView extends HookWidget {
  RegisterView({super.key});
  final emailController =
      TextEditingController(text: 'dev.rutudhvaj@gmail.com'.ifDebugging);
  final passwordController =
      TextEditingController(text: 'Admin@123'.ifDebugging);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Enter your email here...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              keyboardAppearance: Brightness.dark,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                hintText: 'Enter your password here...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              keyboardAppearance: Brightness.dark,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                final email = emailController.text;
                final password = passwordController.text;
                context
                    .read<AppState>()
                    .register(email: email, password: password);
              },
              child: const Text('Register'),
            ),
            TextButton(
              onPressed: () {
                context.read<AppState>().goTo(AppScreen.login);
              },
              child: const Text('Not register yet? Login here!'),
            ),
          ],
        ),
      ),
    );
  }
}
