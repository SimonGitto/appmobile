import 'package:flutter/material.dart';
import 'aggiuntaNota.dart';
import 'scritturaNota.dart';

class PaginaNote extends StatefulWidget {
  @override
  _PaginaNoteState createState() => _PaginaNoteState();
}

class _PaginaNoteState extends State<PaginaNote> {
  List<Map<String, dynamic>> _notes = [];

  void _addNote() async {
    final title = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddNoteTitlePage(),
      ),
    );

    if (title != null && title.isNotEmpty) {
      final newNote = {
        'title': title,
        'content': '',
      };
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddNotePage(
            onSave: (content) {
              setState(() {
                newNote['content'] = content;
                _notes.add(newNote);
              });
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Note'),
      ),
      body:
        ListView.builder(
        itemCount: _notes.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_notes[index]['title']!),
            subtitle: Text(_notes[index]['content']!),
          );
        },
      ),
      floatingActionButton: IconButton(
        icon: const Icon(Icons.add),
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
          backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
          shadowColor: WidgetStateProperty.all<Color>(Colors.red),
        ),
        onPressed: _addNote,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

