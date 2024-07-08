import 'package:flutter/material.dart';

class AddNoteContentPage extends StatelessWidget {
  final String title;
  final TextEditingController _contentController = TextEditingController();

  AddNoteContentPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$title'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(hintText: 'Contenuto della Nota'),
              maxLines: 10,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'title': title,
                  'content': _contentController.text,
                });
              },
              child: Text('Salva Nota'),
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
                shadowColor: WidgetStateProperty.all<Color>(Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
