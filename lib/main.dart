import 'package:flutter/material.dart';

import 'note.dart';
import 'eventi.dart';
import 'impostazioni.dart';


void main() {
  runApp(NoteApp());
}

class NoteApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
   List<String> _listaNote = [];

   List<Widget> _widgetOptions(List<String> listaNote) =>  <Widget>[
    PaginaEventi(),
    PaginaNote(listaNote : _listaNote,onAddNotePressed: _addNote),
    PaginaImpostazioni(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

    void _addNote() async {
    String? newNote = await showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController _textFieldController = TextEditingController();

        return AlertDialog(
          title: Text('Aggiungi Nota'),
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(hintText: "Inserisci la tua nota"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Annulla'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Aggiungi'),
              onPressed: () {
                Navigator.of(context).pop(_textFieldController.text);
              },
            ),
          ],
        );
      },
    );

    if (newNote != null && newNote.isNotEmpty) {
      setState(() {
        _listaNote.add(newNote);
      });
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:const Center(child: Text('Note App')),
      ),
      body: Center(
        child: _widgetOptions(_listaNote).elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Eventi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notes),
            label: 'Note',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Impostazioni',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        onTap: _onItemTapped,
      ),
    );
  }
}
