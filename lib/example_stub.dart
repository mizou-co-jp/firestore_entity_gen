import 'package:firestore_entity_gen/firestore_entity_annotations.dart';
part 'example_stub.g.dart';

@FirestoreEntity(collection: 'users')
class User {
  final String id;
  final String name;
  final int age;
  final DateTime createdAt;

  User({required this.id, required this.name, required this.age, required this.createdAt});
}
