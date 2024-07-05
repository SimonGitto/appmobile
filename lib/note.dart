import 'package:flutter/material.dart';

class PaginaNote extends StatelessWidget {
  final List<String> listaNote;
  final Function() onAddNotePressed; // Callback per gestire il click del pulsante

  PaginaNote({
    required this.listaNote,
    required this.onAddNotePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: listaNote.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(listaNote[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: onAddNotePressed,
              child: Text('Aggiungi Nota'),
            ),
          ),
        ],
      ),
    );
  }
}
