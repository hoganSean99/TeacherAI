import 'package:isar/isar.dart';

part 'student.g.dart';

@Collection()
class Student {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String email;

  @Index()
  String userId;

  String firstName;
  String lastName;
  DateTime? dateOfBirth;
  String? phoneNumber;
  String? address;
  String? subjects;
  DateTime createdAt;
  DateTime updatedAt;

  Student({
    this.id = Isar.autoIncrement,
    required this.email,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.phoneNumber,
    this.address,
    this.subjects,
  })  : createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  String get fullName => '$firstName $lastName';
} 