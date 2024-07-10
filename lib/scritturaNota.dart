import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class AddNotePage extends StatefulWidget {
  final Function(String) onSave;

  AddNotePage({required this.onSave});

  @override
  _AddNotePageState createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final QuillController _controller = QuillController.basic();

  void _saveNote() {
    final content = _controller.document.toPlainText();
    widget.onSave(content);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scrivi Nota'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            QuillToolbar.simple(
              configurations: QuillSimpleToolbarConfigurations(
                controller: _controller,
                  sharedConfigurations: const QuillSharedConfigurations(
                    locale: Locale('it'),
                  ),
                ),
              ),

                Expanded(child: QuillEditor.basic(
                  configurations: QuillEditorConfigurations(
                    controller: _controller,
                    scrollable: true,
                    autoFocus: true,
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
      floatingActionButton: IconButton(
        icon: const Icon(Icons.save),
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
          backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
          shadowColor: WidgetStateProperty.all<Color>(Colors.red),
        ),
        onPressed: _saveNote,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}






/*
child: Text('Salva Nota'),
style: ButtonStyle(
foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
shadowColor: WidgetStateProperty.all<Color>(Colors.red),
),
 */