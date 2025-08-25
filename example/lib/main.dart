import 'package:firestore_entity_gen/firestore_entity_annotations.dart';
part 'main.g.dart';

@FirestoreEntity(collection: 'users')
class User {
  final String id;
  final String name;
  final int age;
  final DateTime createdAt;

  User({required this.id, required this.name, required this.age, required this.createdAt});
}

void main() {
  final u = User(id: '1', name: 'Alice', age: 30, createdAt: DateTime.now());
  final map = u.toFirestore();
  print(map);
  final u2 = _$UserFromFirestore(map);
  print(u2.name);
}
