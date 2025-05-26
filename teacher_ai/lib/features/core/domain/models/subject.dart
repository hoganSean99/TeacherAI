import 'package:isar/isar.dart';

part 'subject.g.dart';

enum ClassYear {
  firstYear,
  secondYear,
  thirdYear,
  transitionYear,
  fifthYear,
  sixthYear,
}

@Collection()
class Subject {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('userId')], unique: true)
  String name;

  @Index()
  String userId;

  String? description;
  String? color;
  DateTime createdAt;
  DateTime updatedAt;
  
  @Enumerated(EnumType.name)
  ClassYear year;

  @Name('studentIds')
  List<int> studentIds;

  Subject({
    this.id = Isar.autoIncrement,
    required this.name,
    required this.userId,
    this.description,
    this.color,
    List<int> studentIds = const [],
    required this.year,
  })  : studentIds = studentIds,
        createdAt = DateTime.now(),
        updatedAt = DateTime.now();
} 