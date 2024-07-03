import 'package:cloud_firestore/cloud_firestore.dart';

import '../state/reminder.dart';

typedef ReminderId = String;

abstract class RemindersProvider {
  Future<void> deleteReminderWithId(
    ReminderId id, {
    required String userId,
  });

  Future<void> deleteAllDocuments({
    required String userId,
  });

  Future<ReminderId> createReminder({
    required String userId,
    required String text,
    required DateTime creationDate,
  });

  Future<void> modify({
    required ReminderId reminderId,
    required bool isDone,
    required String userId,
  });

  Future<Iterable<Reminder>> loadReminders({
    required String userId,
  });
}

class FirestoreRemindersProvider extends RemindersProvider {
  @override
  Future<ReminderId> createReminder(
      {required String userId,
      required String text,
      required DateTime creationDate}) async {
    final reminder = await FirebaseFirestore.instance.collection(userId).add({
      _DocumentKeys.text: text,
      _DocumentKeys.creationDate: creationDate.toIso8601String(),
      _DocumentKeys.isDone: false,
    });
    return reminder.id;
  }

  @override
  Future<void> deleteAllDocuments({required String userId}) async {
    final store = FirebaseFirestore.instance;
    final operation = store.batch();
    final collection = await store.collection(userId).get();
    for (final document in collection.docs) {
      operation.delete(document.reference);
    }
    // Delete all reminders for this user on firebase
    await operation.commit();
  }

  @override
  Future<Iterable<Reminder>> loadReminders({required String userId}) async {
    final collection =
        await FirebaseFirestore.instance.collection(userId).get();

    final reminders = collection.docs.map((e) => Reminder(
          id: e.id,
          text: e[_DocumentKeys.text] as String,
          isDone: e[_DocumentKeys.isDone] as bool,
          creationDate: DateTime.parse(e[_DocumentKeys.creationDate] as String),
        ));
    return reminders;
  }

  @override
  Future<void> modify(
      {required ReminderId reminderId,
      required bool isDone,
      required String userId}) async {
    final collection =
        await FirebaseFirestore.instance.collection(userId).get();

    final firebaseReminder = collection.docs
        .where((element) => element.id == reminderId)
        .first
        .reference;

    firebaseReminder.update({
      _DocumentKeys.isDone: isDone,
    });
  }

  @override
  Future<void> deleteReminderWithId(ReminderId id,
      {required String userId}) async {
    final collection =
        await FirebaseFirestore.instance.collection(userId).get();
    final firebaseReminder =
        collection.docs.firstWhere((element) => element.id == id);
    await firebaseReminder.reference.delete();
  }
}

abstract class _DocumentKeys {
  static const text = 'text';
  static const creationDate = 'creationDate';
  static const isDone = 'isDone';
}
