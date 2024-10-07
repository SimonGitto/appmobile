import 'package:appmobile/scritturaNota.dart';
import 'package:path_provider/path_provider.dart';
import 'aggiuntaTitoloNota.dart';
import 'nota.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';



class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late Box<Note> notesBox;

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    final appDocumentsDirectory = await getApplicationDocumentsDirectory();
    Hive.init(appDocumentsDirectory.path);
    Hive.registerAdapter(NoteAdapter());  // Assicurati di registrare l'adapter
    notesBox = await Hive.openBox<Note>('notesBox');
    setState(() {});  // Ricarica la pagina dopo aver aperto il box
  }

  @override
  void dispose() {
    Hive.close();  // Chiudi Hive quando la pagina viene chiusa
    super.dispose();
  }


  void _navigateToAddNoteTitlePage(BuildContext context) async {
    final title = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => AddNoteTitlePage(
          onTitleSaved: (title) {
            Navigator.of(context).pop(title);
          },
        ),
      ),
    );

    if (title != null && title.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddNotePage(
            onSave: (content) {
              final newNote = Note(
                title: title,
                content: 'content',
                creationDate: DateTime.now(),
              );
            },
            note: Note(title: title, content: '', creationDate: DateTime.now()),
          ),
        ),
      );
    }
  }

  void _addNote() async {
    // Esempio per aggiungere una nota
    final newNote = Note(
      title: 'New Note',
      content: 'Content of the note',
      creationDate: DateTime.now(),
    );
    await notesBox.add(newNote);
    setState(() {});  // Ricarica la pagina per mostrare la nuova nota
  }

  void _saveNote(Note note) {
    notesBox.add(note);
    setState(() {});
  }

  void _editNote(Note note, int index) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddNotePage(
          onSave: (updatedNote) {
            notesBox.putAt(index, updatedNote);
            setState(() {});
          },
          note: note,
        ),
      ),
    );
  }

  void _deleteNote(int index) {
    notesBox.deleteAt(index);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!Hive.isBoxOpen('notesBox')) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Le mie Note'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
      return Scaffold(
        appBar: AppBar(
          title: const Text('Le mie Note'),
        ),
        body: ValueListenableBuilder(
          valueListenable: notesBox.listenable(),
          builder: (context, Box<Note> box, _) {
            if (box.values.isEmpty) {
              return const Center(
                child: Text('Nessuna nota salvata.'),
              );
            } else {
              final notes = box.values.toList();
              return ListView.builder(
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return ListTile(
                    title: Text(note.title),
                    subtitle: Text(
                        'Creato il: ${note.creationDate.toLocal().toString().split(' ')[0]}'
                    ),

                    onTap: () => _editNote(note, index),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteNote(index),
                    ),
                  );
                },
              );
            }
          },
        ),
        floatingActionButton: IconButton(
          icon: const Icon(Icons.add),
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
            backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
            shadowColor: WidgetStateProperty.all<Color>(Colors.red),

          ),
          onPressed: () => _navigateToAddNoteTitlePage(context),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      );

  }
}







/*
floatingActionButton: IconButton(
          icon: const Icon(Icons.add),
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
            backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
            shadowColor: WidgetStateProperty.all<Color>(Colors.red),

          ),
          onPressed: () => _navigateToAddNoteTitlePage(context),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
 */



