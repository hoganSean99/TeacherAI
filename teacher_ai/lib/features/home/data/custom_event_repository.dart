import 'package:isar/isar.dart';
import '../domain/models/custom_event.dart';

class CustomEventRepository {
  final Isar isar;
  CustomEventRepository(this.isar);

  Future<void> addEvent(CustomEvent event) async {
    await isar.writeTxn(() async {
      await isar.customEvents.put(event);
    });
  }

  Future<List<CustomEvent>> getEventsByUserId(String userId) async {
    return await isar.customEvents.filter().userIdEqualTo(userId).findAll();
  }

  Future<void> deleteEvent(int id) async {
    await isar.writeTxn(() async {
      await isar.customEvents.delete(id);
    });
  }

  Future<void> updateEvent(CustomEvent event) async {
    await isar.writeTxn(() async {
      await isar.customEvents.put(event);
    });
  }
} 