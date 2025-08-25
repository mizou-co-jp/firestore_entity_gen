part of 'package:firestore_entity_gen/example_stub.dart';

extension UserFirestoreExtension on User {
  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'age': age,
    'createdAt': createdAt.toIso8601String(),
  };
}

User _$UserFromFirestore(Map<String, dynamic> map) => User(
  id: map['id'] as String,
  name: map['name'] as String,
  age: map['age'] as int,
  createdAt: DateTime.parse(map['createdAt'] as String),
);

// public wrapper for tests/importers
User userFromFirestore(Map<String, dynamic> map) => _$UserFromFirestore(map);
