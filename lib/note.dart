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
import 'package:intl/intl.dart';

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
      print("Errore: $e");
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

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd_HH.mm.ss').format(date);
  }

  void _navigateToAddNoteTitlePage(BuildContext context) async {
    final now = DateTime.now();
    final defaultTitle = _formatDate(now);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddNotePage(
          onSave: (note) async {
            await notesBox.add(note);
            setState(() {});
          },
          note: Note(
            title: defaultTitle,
            content: '',
            creationDate: now,
            lastModifiedDate: now,
          ),
        ),
      ),
    );
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

  void _confirmDelete(BuildContext context, Note note, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma Eliminazione'),
          content: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                const TextSpan(text: 'Sei sicuro di voler eliminare la nota '),
                TextSpan(
                  text: note.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Elimina'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteNote(index);
              },
            ),
          ],
        );
      },
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
                leading: const Icon(Icons.delete_rounded),
                title: const Text('Elimina'),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDelete(context, note, index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_rounded),
                title: const Text('Condividi con QR'),
                onTap: () {
                  _showQRCode(context, note);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copia testo'),
                onTap: () {
                  Navigator.of(context).pop();
                  final plainText = Document.fromJson(jsonDecode(note.content)).toPlainText();
                  if (plainText.length > 100000) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Testo troppo lungo!"),
                          content: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                              children: [
                                const TextSpan(text: "La nota "),
                                TextSpan(
                                  text: note.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: " supera i 100.000 caratteri e non può essere copiata negli appunti."),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text("OK"),
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
                leading: const Icon(Icons.info_rounded),
                title: const Text('Info'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showNoteInfo(context, note);
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
          title: const Text('Info Nota'),
          content: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: <TextSpan>[
                const TextSpan(text: 'Titolo: ', style: TextStyle(fontWeight: FontWeight.normal)),
                TextSpan(text: note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '\nData creazione: ${_formatDate(note.creationDate)}\n'),
                TextSpan(text: 'Ultima modifica: ${_formatDate(note.lastModifiedDate ?? DateTime.now())}\n'),
                TextSpan(text: 'Numero di parole: $wordCount\n'),
                TextSpan(text: 'Numero di caratteri: $characterCount'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Chiudi'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showQRCode(BuildContext context, Note note) {
    final noteContent = note.content;
    final contentLength = noteContent.characters.length;

    if (contentLength > 2500) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Testo troppo lungo!'),
            content: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black), // Colore del testo
                children: [
                  TextSpan(text: 'La nota ', style: const TextStyle(fontWeight: FontWeight.normal)), // Testo normale
                  TextSpan(text: note.title, style: const TextStyle(fontWeight: FontWeight.bold)), // Titolo in grassetto
                  const TextSpan(text: ' supera il limite massimo di caratteri per generare un codice QR.'),
                ],
              ),
            ),
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
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  note.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                  size: 300.0,
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
              child: Text(
                'Nessuna nota salvata',
                style: TextStyle(fontSize: 24),
              ),
            );
          } else {
            final notes = box.values.toList();
            return ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return ListTile(
                  title: Text(
                      note.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Ultima modifica: ${_formatDate(note.lastModifiedDate ?? DateTime.now())}',
                  ),
                  onTap: () => _editNote(note, index),
                  onLongPress: () => _showNoteOptions(context, note, index),
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
