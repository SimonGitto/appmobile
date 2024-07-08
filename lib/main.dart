import 'package:flutter/material.dart';

import 'note.dart';
import 'eventi.dart';
import 'impostazioni.dart';
import 'line.dart';
import 'aggiuntaNota.dart';
import 'scritturaNota.dart';

void main() {
  runApp(NoteApp());
}

class NoteApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App',
      theme: ThemeData(
        primarySwatch: Colors.red,
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
  List<Map<String, String>> _listaNote = [];

   List<Widget> _widgetOptions() {
     return <Widget>[
       TopLine(child: PaginaEventi()),
       TopLine(child: PaginaNote(
           listaNote: _listaNote, onAddNotePressed: _addNote)),
       TopLine(child: PaginaImpostazioni()),
     ];
   }

     void _onItemTapped(int index) {
       setState(() {
         _selectedIndex = index;
       });
     }

     void _addNote() async {
       String? noteTitle = await Navigator.of(context).push(
         MaterialPageRoute(builder: (context) => AddNoteTitlePage()),
       );

       if (noteTitle != null && noteTitle.isNotEmpty) {
         Map<String, String>? noteContent = await Navigator.of(context).push(
           MaterialPageRoute(builder: (context) => AddNoteContentPage(title: noteTitle)),
         );

         if (noteContent != null && noteContent['content']!.isNotEmpty) {
           setState(() {
             _listaNote.add({
               'title': noteTitle,
               'content': noteContent['content']!,
             });
           });
         }
       }
     }

     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(
           title:Text(
               'Note App',
               style:TextStyle(
                 color:Colors.red,
                 fontWeight: FontWeight.bold,
                 fontSize: 24,
               )),
         ),
         body: Center(
           child: _widgetOptions().elementAt(_selectedIndex),
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
