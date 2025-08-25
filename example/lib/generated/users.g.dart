part of 'users.dart';

enum Name {
  Alice,
  Bob,
}

extension UserFirestoreExtension on User {
  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'age': age,
    'createdAt': createdAt.toIso8601String(),
  };
}

User _$UserFromFirestore(Map<String, dynamic> map) {
  return User(
    id: map['id'] as String,
    name: map['name'] as String,
    age: map['age'] as int,
    createdAt: DateTime.parse(map['createdAt'] as String),
  );
}
