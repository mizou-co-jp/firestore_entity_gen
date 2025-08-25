import 'package:test/test.dart';
import 'package:firestore_entity_gen/example_stub.dart';

void main() {
  test('example user serialization roundtrip', () {
    final u = User(id: '1', name: 'Alice', age: 30, createdAt: DateTime.parse('2020-01-01T00:00:00Z'));
    final map = u.toFirestore();
    expect(map['id'], '1');
  final u2 = userFromFirestore(map);
    expect(u2.name, 'Alice');
  });
}
