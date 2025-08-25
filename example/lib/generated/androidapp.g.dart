part of 'androidapp.dart';

extension AndroidAppFirestoreExtension on AndroidApp {
  Map<String, dynamic> toFirestore() => {
    'appState': appState,
    'appTitle': appTitle,
    'appType': appType,
    'comment': comment,
    'detail': detail,
    'explanation': explanation,
    'icon': icon,
    'id': id,
    'images': images,
    'publicationState': publicationState,
    'time': time,
    'web': web,
  };
}

AndroidApp _$AndroidAppFromFirestore(Map<String, dynamic> map) {
  return AndroidApp(
    appState: map['appState'] as int,
    appTitle: map['appTitle'] as String,
    appType: map['appType'] as int,
    comment: map['comment'] as String,
    detail: map['detail'] as String,
    explanation: map['explanation'] as String,
    icon: map['icon'] as String,
    id: map['id'] as String,
    images: map['images'] as String,
    publicationState: map['publicationState'] as int,
    time: map['time'] as String,
    web: map['web'] as String,
  );
}
