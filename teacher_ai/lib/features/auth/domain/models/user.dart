import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';

part 'user.g.dart';

@collection
class User {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String uuid;

  @Index(unique: true)
  String email;

  String password; // In production, this should be properly hashed
  String firstName;
  String lastName;
  String title;
  DateTime createdAt;
  DateTime updatedAt;

  User({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.title,
  })  : uuid = const Uuid().v4(),
        createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  String get displayName => '$title $firstName $lastName';
} 