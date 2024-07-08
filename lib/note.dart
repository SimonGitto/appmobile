import 'package:flutter/material.dart';

class PaginaNote extends StatelessWidget {
  final List<Map<String, String>> listaNote;
  final Function() onAddNotePressed;// Callback per gestire il click del pulsante

  PaginaNote({
    required this.listaNote,
    required this.onAddNotePressed,

  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Note'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: listaNote.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(listaNote[index]['title']!),
                  subtitle: Text(listaNote[index]['content']!),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: onAddNotePressed,
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
                shadowColor: WidgetStateProperty.all<Color>(Colors.red),
              ),
              child: Text('+'),
            ),
          ),
        ],
      ),
    );
  }


}
