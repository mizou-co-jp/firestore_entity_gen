import 'package:firestore_entity_gen/firestore_entity_annotations.dart';
part 'androidapp.g.dart';

@FirestoreEntity(collection: 'AndroidApp')
class AndroidApp {
  final String id;
  final String comment;
  final String web;
  final String explanation;
  final int appType;
  final String detail;
  final int publicationState;
  final String time;
  final String images;
  final int appState;
  final String icon;
  final String appTitle;

  AndroidApp({required this.id, required this.comment, required this.web, required this.explanation, required this.appType, required this.detail, required this.publicationState, required this.time, required this.images, required this.appState, required this.icon, required this.appTitle });
}
