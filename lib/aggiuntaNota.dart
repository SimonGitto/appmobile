import 'package:flutter/material.dart';

class AddNoteTitlePage extends StatefulWidget {
  @override
  _AddNoteTitlePageState createState() => _AddNoteTitlePageState();
}

class _AddNoteTitlePageState extends State<AddNoteTitlePage> {
  final _titleController = TextEditingController();

  void _saveTitle() {
    Navigator.of(context).pop(_titleController.text);
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



/*
child: Text('Continua'),
style: ButtonStyle(
foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
shadowColor: WidgetStateProperty.all<Color>(Colors.red),
),

 */