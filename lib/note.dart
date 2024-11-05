import 'dart:convert';

import 'package:appmobile/scritturaNota.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:path_provider/path_provider.dart';
import 'aggiuntaTitoloNota.dart';
import 'nota.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';



class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late Box<Note> notesBox;
  bool isLoading = true;


  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    try {
      final appDocumentsDirectory = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentsDirectory.path);
      notesBox = await Hive.openBox<Note>('notesBox');
      print("aperto bene");
    } catch (e) {
      print("Errore diocan : $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    if (Hive.isBoxOpen('notesBox')) {
      Hive.close();
    }
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
            onSave: (note) async {
              await notesBox.add(note);
              setState(() {});
            },
            note: Note(title: title, content: '', creationDate: DateTime.now(), lastModifiedDate: DateTime.now()),
          ),
        ),
      );
    }
  }



  void _editNote(Note note, int index) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddNotePage(
          onSave: (updatedNote) {
            updatedNote.lastModifiedDate = DateTime.now();
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



  void _showNoteOptions(BuildContext context, Note note, int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: Wrap(
            children: <Widget>[

              ListTile(
                leading: Icon(Icons.delete_rounded),
                title: Text('Elimina'),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteNote(index);
                },
              ),

              ListTile(
                leading: Icon(Icons.qr_code_rounded),
                title: Text('Condividi con QR'),
                onTap: () {
                  _showQRCode(context, note.content);
                },
              ),

              ListTile(
                leading: Icon(Icons.copy_rounded),
                title: Text('Copia testo'),
                onTap: () {
                  Navigator.of(context).pop();
                  final plainText = Document.fromJson(jsonDecode(note.content)).toPlainText();
                  if (plainText.length > 100000) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Testo troppo lungo"),
                          content: Text("La nota supera i 100.000 caratteri e non può essere copiata negli appunti."),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text("OK"),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    Clipboard.setData(ClipboardData(text: plainText));
                  }
                },
              ),

              ListTile(
                leading: Icon(Icons.info_rounded),
                title: Text('Info'),
                onTap: () {
                  Navigator.of(context).pop(); // Chiude il menù
                  _showNoteInfo(context, note); // Mostra info
                },
              ),
            ],
          ),
        );
      },
    );
  }


    void _showNoteInfo(BuildContext context, Note note) {
      final content = note.content;
      final wordCount = content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;
      final characterCount = content.length;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Info Nota'),
            content: Text(
                'Titolo: ${note.title}\n'
                'Data creazione: ${note.creationDate.toLocal().toString().split(' ')[0]}\n'
                'Ultima modifica: ${note.lastModifiedDate?.toLocal().toString().split(' ')[0]}\n\n'
                    'Numero di parole: $wordCount\n'
                    'Numero di caratteri: $characterCount',
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Chiudi'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }

  void _showQRCode(BuildContext context, String noteContent) {
    final contentLength = noteContent.characters.length;

    if (contentLength > 2500) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Testo troppo lungo!'),
            content: const Text('La nota supera il limite massimo di caratteri per generare un codice QR.'),
            actions: <Widget>[
              TextButton(
                child: const Text('Chiudi'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: MediaQuery.of(context).size.width, // Larghezza quasi a schermo intero
            height: MediaQuery.of(context).size.height * 0.6, // Altezza dello schermo
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Condividi Nota con QR',
                  style: TextStyle(fontSize: 24), // Aumenta la dimensione del titolo
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (contentLength > 970)
                  const Text(
                    'Attenzione: Questo QR potrebbe non essere leggibile a causa della lunghezza del testo.',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                if (contentLength > 1000) const SizedBox(height: 10),
                QrImageView(
                  data: noteContent,
                  version: QrVersions.auto,
                  size: 300.0, // Dimensione del QR code
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Chiudi'),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      body: ValueListenableBuilder(
        valueListenable: notesBox.listenable(),
        builder: (context, Box<Note> box, _) {
          if (box.values.isEmpty) {
            return const Center(
              child: Text('Nessuna nota salvata.'),
            );             } else {
            final notes = box.values.toList();
            return ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return ListTile(
                  title: Text(note.title),
                  subtitle: Text(
                    'Ultima modifica: ${note.lastModifiedDate?.toLocal().toString().split(' ')[0]}',
                  ),
                  onTap: () => _editNote(note, index),
                  onLongPress: () =>_showNoteOptions(context, note, index),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: IconButton(
        icon:  const Icon(Icons.add),
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



