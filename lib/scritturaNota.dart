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
    } else {
      _controller = QuillController.basic();
    }
  }

  void _saveNote() {
    final content = jsonEncode(_controller.document.toDelta().toJson());
    final note = Note(
      title: widget.note?.title ?? '',
      content: content,
      creationDate: widget.note?.creationDate ?? DateTime.now(),
    );
    widget.onSave(note);
    Navigator.of(context).pop();
  }

  void _editTitle() {
    final titleController = TextEditingController(text: widget.note?.title);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
              'Modifica il titolo',
              style: TextStyle(color: Colors.black),
          ),
          content: TextField(
            controller: titleController,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                // Aggiorna il titolo nella nota
                setState(() {
                  widget.note!.title = titleController.text;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Conferma'),
            ),
          ],
        );
      },
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              Navigator.of(context).pop();
            }
        ),
        title: GestureDetector(
          onTap: _editTitle,
          child: Text(
            widget.note?.title.isNotEmpty == true ? widget.note!.title : 'Scrivi la tua nota',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all<Color>(Colors.red),
              backgroundColor: WidgetStateProperty.all<Color>(Colors.transparent),
              shadowColor: WidgetStateProperty.all<Color>(Colors.transparent),
            ),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const SizedBox(height: 0), // Riduce lo spazio tra l'AppBar e la toolbar
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
                  expands: true,
                  placeholder: 'Scrivi il contenuto della nota qui...',
                  sharedConfigurations: const QuillSharedConfigurations(
                    locale: Locale('it'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
