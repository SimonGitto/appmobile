import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'nota.dart';
import 'dart:convert';


class AddNotePage extends StatefulWidget {
  final Function(Note) onSave;
  final Note? note;

  AddNotePage({required this.onSave, this.note});

  @override
  _AddNotePageState createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  late TextEditingController _titleController ;
  late QuillController _controller;


  @override
  void initState() {
    super.initState();

    if (widget.note != null) {
      try {
        final doc = Document.fromJson(jsonDecode(widget.note!.content));
        _controller = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        _controller = QuillController.basic();
      }
      _titleController = TextEditingController(text: widget.note!.title);
    } else {
      _controller = QuillController.basic();
      _titleController = TextEditingController();
    }
  }



  void _saveNote() {
    final content = jsonEncode(_controller.document.toDelta().toJson());
    final note = Note(
      title: _titleController.text,
      content: content,
      creationDate: widget.note?.creationDate ?? DateTime.now(),
    );
    widget.onSave(note);
    Navigator.of(context).pop();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [IconButton(
          icon: const Icon(Icons.save),
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
            backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
            shadowColor: WidgetStateProperty.all<Color>(Colors.red),
          ),
          onPressed: _saveNote,
        ),],
        title: Text('Scrivi la tua nota'),
      ),
      body: Padding(

        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            QuillToolbar.simple(
              configurations: QuillSimpleToolbarConfigurations(
                controller: _controller,
                multiRowsDisplay: false,
                showClipboardCut: false,
                showClipboardCopy: false,
                showClipboardPaste: false,
                sharedConfigurations: const QuillSharedConfigurations(
                  locale: Locale('it'),

                ),
              ),
            ),

            Expanded(
                child: QuillEditor.basic(
                  configurations: QuillEditorConfigurations(
                    controller: _controller,
                    scrollable: true,
                    autoFocus: false,
                    expands: false,

                    placeholder: 'Scrivi la tua nota qui...',
                    sharedConfigurations: const QuillSharedConfigurations(
                      locale: Locale('it')
                  )
              ),
            )
            ),
          ],
        ),
      ),
    );
  }
}












