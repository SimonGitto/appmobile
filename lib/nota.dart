import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String content;

  @HiveField(2)
  DateTime creationDate;

  @HiveField(3)
  DateTime? lastModifiedDate;

  @HiveField(4)
  String? audio;

  Note({
    required this.title,
    required this.content,
    required this.creationDate,
    DateTime? lastModifiedDate,
    required this.audio,
  }): lastModifiedDate = lastModifiedDate ?? creationDate;
}

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 0;

  @override
  Note read(BinaryReader reader) {
    return Note(
      title: reader.readString(),
      content: reader.readString(),
      creationDate: DateTime.parse(reader.readString()),
      lastModifiedDate: DateTime.parse(reader.readString()),
      audio: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer.writeString(obj.title);
    writer.writeString(obj.content);
    writer.writeString(obj.creationDate.toIso8601String());
    writer.writeString(obj.lastModifiedDate!.toIso8601String());
    writer.writeString(obj.audio ?? '');
  }
}


