import 'package:flutter/material.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'nota.dart';
import 'note.dart';
import 'eventi.dart';
import 'impostazioni.dart';
import 'line.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('it_IT', null);
  final directory = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(directory.path);

  Hive.registerAdapter(NoteAdapter());

  runApp(NoteApp());
}

class NoteApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      title: 'Note App',
      theme: ThemeData(
          dialogTheme: const DialogTheme(
            titleTextStyle: TextStyle(color: Colors.red, fontSize: 20),
            contentTextStyle: TextStyle(color: Colors.black, fontSize: 16),
          ),

          textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
              overlayColor: MaterialStateProperty.all<Color>(Colors.red.shade100),
              foregroundColor: MaterialStateProperty.all<Color>(Colors.red),
              backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
            ),
          ),

          primarySwatch: Colors.red,
          timePickerTheme: TimePickerThemeData(
            dialBackgroundColor: Colors.grey[250],
            dialHandColor: Colors.red,
            hourMinuteTextColor: MaterialStateColor.resolveWith((states) =>
            states.contains(MaterialState.selected) ? Colors.red : Colors.black),
            hourMinuteColor: MaterialStateColor.resolveWith((states) =>
            states.contains(MaterialState.selected) ? Colors.transparent : Colors.transparent),
          ),

          textSelectionTheme: TextSelectionThemeData(
            cursorColor: Colors.black,
            selectionColor: Colors.red.withOpacity(0.3),
            selectionHandleColor: Colors.transparent,
          ),

          inputDecorationTheme: const InputDecorationTheme(
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.transparent),
            ),
            labelStyle: TextStyle(color: Colors.red),
          )
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
  final List<Widget> _widgetOptions = <Widget>[
    TopLine(child: CalendarioPage()),
    TopLine(child:NotesPage()),
    TopLine(child:PaginaImpostazioni()),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note App'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: Colors.grey,
            height: 2.0,
          ),
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Calendario',
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
