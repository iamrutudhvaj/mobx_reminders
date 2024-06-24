import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobx/mobx.dart';

import '../auth/auth_error.dart';
import 'reminder.dart';

part 'app_state.g.dart';

class AppState = _AppState with _$AppState;

abstract class _AppState with Store {
  @observable
  AppScreen currentScreen = AppScreen.login;

  @observable
  bool isLoading = false;

  @observable
  User? currentUser;

  @observable
  AuthError? authError;

  @observable
  ObservableList<Reminder> reminders = ObservableList<Reminder>();

  @computed
  ObservableList<Reminder> get sortedReminders =>
      ObservableList.of(reminders.sorted());

  @action
  void goTo(AppScreen screen) {
    currentScreen = screen;
  }

  @action
  Future<bool> delete(Reminder reminder) async {
    isLoading = true;
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      isLoading = false;
      return false;
    }
    final userId = user.uid;
    final collection =
        await FirebaseFirestore.instance.collection(userId).get();
    try {
      final firebaseReminder =
          collection.docs.firstWhere((element) => element.id == reminder.id);

      // Delete from Firebase
      await firebaseReminder.reference.delete();

      // Delete from Local Variable
      reminders.removeWhere((element) => element.id == reminder.id);
      return true;
    } catch (_) {
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<bool> deleteAccount() async {
    isLoading = true;
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      isLoading = false;
      return false;
    }
    final userId = user.uid;

    try {
      final store = FirebaseFirestore.instance;
      final operation = store.batch();
      final collection = await store.collection(userId).get();
      for (final document in collection.docs) {
        operation.delete(document.reference);
      }
      // Delete all reminders for this user on firebase
      await operation.commit();
      // Delete the user from firebase
      await user.delete();
      // logout the user
      await auth.signOut();
      // change current screen
      currentScreen = AppScreen.login;
      return true;
    } on FirebaseAuthException catch (e) {
      authError = AuthError.from(e);
      return false;
    } catch (_) {
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> logout() async {
    isLoading = true;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Just Ignore Catch Errors
    }
    isLoading = false;
    reminders.clear();
    currentScreen = AppScreen.login;
  }

  @action
  Future<bool> createReminder(String text) async {
    isLoading = true;
    final userId = currentUser?.uid;
    if (userId == null) {
      return false;
    }

    final creationDate = DateTime.now();

    // Create Firebase Reminder
    final firebaseReminder =
        await FirebaseFirestore.instance.collection(userId).add({
      _DocumentKeys.text: text,
      _DocumentKeys.creationDate: creationDate.toIso8601String(),
      _DocumentKeys.isDone: false,
    });

    // Create Local Reminder
    final reminder = Reminder(
      id: firebaseReminder.id,
      text: text,
      isDone: false,
      creationDate: creationDate,
    );
    reminders.add(reminder);

    isLoading = false;
    return true;
  }

  @action
  Future<bool> modify(
    Reminder reminder, {
    required bool isDone,
  }) async {
    final userId = currentUser?.uid;
    if (userId == null) {
      return false;
    }

    final collection =
        await FirebaseFirestore.instance.collection(userId).get();

    final firebaseReminder = collection.docs
        .where((element) => element.id == reminder.id)
        .first
        .reference;

    firebaseReminder.update({
      _DocumentKeys.isDone: isDone,
    });

    reminders.firstWhere((element) => element.id == reminder.id).isDone =
        isDone;

    return true;
  }

  @action
  Future<void> initialize() async {
    isLoading = true;
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await _loadReminders();
      currentScreen = AppScreen.reminders;
    } else {
      currentScreen = AppScreen.login;
    }
    isLoading = false;
  }

  @action
  Future<bool> _loadReminders() async {
    final userId = currentUser?.uid;
    if (userId == null) {
      return false;
    }
    final collection =
        await FirebaseFirestore.instance.collection(userId).get();

    final reminders = collection.docs
        .map((e) => Reminder(
              id: e.id,
              text: e[_DocumentKeys.text] as String,
              isDone: e[_DocumentKeys.isDone] as bool,
              creationDate:
                  DateTime.parse(e[_DocumentKeys.creationDate] as String),
            ))
        .toList();
    this.reminders = ObservableList.of(reminders);
    return true;
  }

  @action
  Future<bool> _registerOrLogin({
    required LoginOrRegistrationFunction fn,
    required String email,
    required String password,
  }) async {
    authError = null;
    isLoading = true;
    try {
      await fn(email: email, password: password);
      currentUser = FirebaseAuth.instance.currentUser;
      await _loadReminders();
      return true;
    } on FirebaseAuthException catch (e) {
      currentUser = null;
      authError = AuthError.from(e);
      return false;
    } finally {
      isLoading = false;
      if (currentUser != null) {
        currentScreen = AppScreen.reminders;
      }
    }
  }

  @action
  Future<bool> register({
    required String email,
    required String password,
  }) =>
      _registerOrLogin(
        fn: FirebaseAuth.instance.createUserWithEmailAndPassword,
        email: email,
        password: password,
      );

  @action
  Future<bool> login({
    required String email,
    required String password,
  }) =>
      _registerOrLogin(
        fn: FirebaseAuth.instance.signInWithEmailAndPassword,
        email: email,
        password: password,
      );
}

abstract class _DocumentKeys {
  static const text = 'text';
  static const creationDate = 'creationDate';
  static const isDone = 'isDone';
}

typedef LoginOrRegistrationFunction = Future<UserCredential> Function(
    {required String email, required String password});

extension ToInt on bool {
  int toInteger() => this ? 1 : 0;
}

extension Sorted on List<Reminder> {
  List<Reminder> sorted() => [...this]..sort((lhs, rhs) {
      final isDone = lhs.isDone.toInteger().compareTo(rhs.isDone.toInteger());
      if (isDone != 0) {
        return isDone;
      }

      final creationDateComparison =
          lhs.creationDate.compareTo(rhs.creationDate);
      if (creationDateComparison != 0) {
        return creationDateComparison;
      }

      return lhs.hashCode.compareTo(rhs.hashCode);
    });
}

enum AppScreen { login, register, reminders }
