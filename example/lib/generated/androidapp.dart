import 'package:firestore_entity_gen/firestore_entity_annotations.dart';
part 'androidapp.g.dart';

@FirestoreEntity(collection: 'AndroidApp')
class AndroidApp {
  final String id;
  final String images;
  final String time;
  final String explanation;
  final int appState;
  final String web;
  final int appType;
  final String icon;
  final String comment;
  final String detail;
  final int publicationState;
  final String appTitle;

  AndroidApp({required this.id, required this.images, required this.time, required this.explanation, required this.appState, required this.web, required this.appType, required this.icon, required this.comment, required this.detail, required this.publicationState, required this.appTitle });
}
