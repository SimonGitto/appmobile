import 'package:flutter/material.dart';


class AddNoteTitlePage extends StatefulWidget {
  final Function(String) onTitleSaved;
  AddNoteTitlePage({required this.onTitleSaved});

  @override
  _AddNoteTitlePageState createState() => _AddNoteTitlePageState();
}

class _AddNoteTitlePageState extends State<AddNoteTitlePage> {
  final TextEditingController _titleController = TextEditingController();

  void _saveTitle() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            duration: Duration(seconds:  3),
            content: Text('Il titolo non può essere vuoto')
        ),
      );
      return;
    }
    Navigator.of(context).pop(title); // Return the title back to NotesPage
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inserisci Titolo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Titolo',
          ),
        ),
      ),
      floatingActionButton: IconButton(
        icon: const Icon(Icons.save),
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
          backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
          shadowColor: WidgetStateProperty.all<Color>(Colors.red),
        ),
        onPressed: _saveTitle,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}


