import 'dart:convert';
import 'package:appmobile/scritturaNota.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'aggiuntaTitoloNota.dart';
import 'nota.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';



class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late Box<Note> notesBox;
  bool isLoading = true;
  bool showTextNotes = true;
  FlutterSoundRecorder? _audioRecorder;
  FlutterSoundPlayer? _audioPlayer;
  String? audioFilePath;
  Duration _recordingDuration =Duration.zero;
  Timer? _recordingTimer;
  Timer? _playingTimer;
  bool _isRecording = false;
  bool _isPlaying = false;
  Duration _playingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _openBox();
    _audioRecorder = FlutterSoundRecorder();
    _audioPlayer = FlutterSoundPlayer();
    _initRecorder();
  }


  Future<void> _openBox() async {
    try {
      final appDocumentsDirectory = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentsDirectory.path);
      notesBox = await Hive.openBox<Note>('notesBox');
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Errore nell'aprire il box: $e");
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<void> checkAndRequestPermission() async {
    if (await Permission.microphone.isDenied) {
      await Permission.microphone.request();
    }
  }



  @override
  void dispose() {
    if (Hive.isBoxOpen('notesBox')) {
      Hive.close();
    }
    _audioRecorder!.closeRecorder();
    super.dispose();
  }


  Future<void> _initRecorder() async {
    await _audioRecorder!.openRecorder();
    await Permission.microphone.request();
  }



  void _showRecordingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {

            return AlertDialog(
              title: const Text(
                  "Registrazione in corso...",
                style: TextStyle(
                  color: Colors.black
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _stopRecording();
                    Navigator.of(context).pop();
                  },
                  child: const Text("Scarta"),
                ),

                TextButton(
                  onPressed: () {
                    _stopRecording();
                    _confirmSaveRecording();
                  },
                  child: const Text("Salva"),
                ),

              ],
            );
          },
        );

  }





  void _startRecording() async {
    if (_isRecording) return;

    await checkAndRequestPermission();

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _audioRecorder!.startRecorder(toFile: path);

    setState(() {
      audioFilePath = path;
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });

    _showRecordingDialog();
  }




  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    await _audioRecorder!.stopRecorder();

    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }




  Future<void> _confirmSaveRecording() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController titleController = TextEditingController();

        return AlertDialog(
          title: const Text(
            "Salva Registrazione",
            style: TextStyle(
              color: Colors.black
            ),
          ),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(
                labelText: "Titolo della nota",
                labelStyle: TextStyle(
                  color: Colors.black
                )
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text("Annulla"),
            ),

            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  _addAudioNote(titleController.text);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
                String x = _formatDate(DateTime.now());
                _addAudioNote(x);
                Navigator.of(context).pop();
                Navigator.of(context).pop();

              },
              child: const Text("Salva"),
            ),

          ],
        );
      },
    );
  }



  void _addAudioNote(String title) {
    if (audioFilePath != null) {
      final note = Note(
        title: title,
        content: '',
        creationDate: DateTime.now(),
        lastModifiedDate: DateTime.now(),
        audio: audioFilePath!,
      );

      notesBox.add(note);

      setState(() {
        audioFilePath = null;
      });
    }
  }




  void _showPlaybackDialog(String? filePath) {
    _playRecording(filePath!);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Riproduzione in corso...",
              style:TextStyle(
                  color: Colors.black
              )
          ),
          actions: [
            TextButton(
              onPressed: () {
                _stopPlaying();
                Navigator.of(context).pop();
              },
              child: Text("Chiudi"),

            ),
          ],
        );
      },
    );
  }



  Future<void> _playRecording(String filePath) async {
    try {
      await _audioPlayer!.openPlayer();
      await _audioPlayer!.startPlayer(
        fromURI: filePath,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
          });
        },
      );

      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      print("Errore durante la riproduzione: $e");
    }
  }




  void _stopPlaying() async {
    if (_isPlaying) {
      await _audioPlayer?.stopPlayer();
      setState(() {
        _isPlaying = false;
        _recordingDuration = Duration.zero;
      });
    }
  }



  void _showAudioOptions(BuildContext context, Note note, int index) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0), // Aggiungi padding per migliorare l'aspetto
          child: Column(
            mainAxisSize: MainAxisSize.min, // Assicura che il contenuto si adatti solo alla dimensione necessaria
            children: <Widget>[
              ListTile(
                leading: const Icon(
                    Icons.delete_rounded,
                    color: Colors.red,
                ),
                title: const Text(
                    'Elimina',
                    style: TextStyle(
                      color: Colors.red
                    ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmDelete(context, note, index);
                },
              ),
              // Puoi aggiungere altre opzioni qui in futuro
            ],
          ),
        );
      },
    );
  }



  //note scritte--------------------------------------------------------------------------------------

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
            audio: '',
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
                leading: const Icon(
                  Icons.delete_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                    'Elimina',
                  style: TextStyle(
                      color: Colors.red
                  ),
                ),
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
                  data: extractTextFromJson(noteContent),
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



  String extractTextFromJson(String jsonText) {
    try {
      var decoded = json.decode(jsonText);

      if (decoded is List && decoded.isNotEmpty) {
        var firstElement = decoded[0];
        if (firstElement is Map && firstElement.containsKey('insert')) {
          return firstElement['insert']?.toString() ?? '';
        }
      }

      return '';
    } catch (e) {
      print("Errore nella decodifica JSON: $e");
      return '';
    }
  }




  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(

      body: Column(
        children: [
          const SizedBox(height: 10.0), // Spazio verticale
          Center(
            child: ToggleButtons(
              color: Colors.black,
              selectedColor: Colors.red,
              fillColor: Colors.transparent,
              borderWidth: 1.25,
              borderColor: Colors.black,
              selectedBorderColor: Colors.red,
              borderRadius: BorderRadius.circular(15),
              isSelected: [showTextNotes, !showTextNotes],
              onPressed: (index) {
                setState(() {
                  showTextNotes = index == 0;
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(' Note '),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text('Audio'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0), // Spazio tra il bottone di switch e il contenuto
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: notesBox.listenable(),
              builder: (context, Box<Note> box, _) {
                final notes = box.values.toList();
                final filteredNotes = showTextNotes
                    ? notes.where((note) => note.audio?.isEmpty ?? true).toList()
                    : notes.where((note) => note.audio?.isNotEmpty ?? false).toList();

                if (filteredNotes.isEmpty) {
                  return Center(
                    child: Text(
                      showTextNotes ? 'Nessuna nota testuale salvata.' : 'Nessuna nota vocale salvata.',
                      style: const TextStyle(fontSize: 24),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return ListTile(
                      title: Text(
                        note.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: showTextNotes
                      ? Text('Ultima modifica: ${_formatDate(note.lastModifiedDate ?? DateTime.now())}')
                      : Text('Data di creazione: ${_formatDate(note.lastModifiedDate ?? DateTime.now())}',
                      ),
                      onTap: showTextNotes
                          ? () => _editNote(note, index)
                          : () => _showPlaybackDialog(note.audio),
                      onLongPress: showTextNotes
                          ? () => _showNoteOptions(context, note, index)
                          : () => _showAudioOptions(context, note, index),

                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: showTextNotes
          ? IconButton(
        onPressed: () => _navigateToAddNoteTitlePage(context),
        icon: const Icon(Icons.add),
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
          backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
          shadowColor: WidgetStateProperty.all<Color>(Colors.red),
        ),
      )

          : IconButton(
        onPressed: _startRecording,
        icon: const Icon(Icons.mic),
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
          backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
          shadowColor: WidgetStateProperty.all<Color>(Colors.red),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

}