import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';


class CalendarioPage extends StatefulWidget {
  @override
  _CalendarioPageState createState() => _CalendarioPageState();
}


class _CalendarioPageState extends State<CalendarioPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _events = [];
  bool _isCalendarVisible = true;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Rome'));
    _loadReminders();
    initializeNotifications();
  }





  void initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    if (Platform.isAndroid) {
      final granted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled() ?? false;

      if (granted) {
        print("Permesso per le notifiche concesso.");
      } else {
        print("Permesso per le notifiche negato. Vai nelle impostazioni per attivarlo.");
        _openAppSettings(); // Chiama la funzione per aprire le impostazioni
      }
    }
  }

  void _openAppSettings() async {
    const url = 'app-settings:'; // URL per aprire le impostazioni dell'app
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print("Non è stato possibile aprire le impostazioni dell'app.");
    }
  }




  Future<bool> isAndroid13OrAbove() async {
    final version = int.tryParse(Platform.version.split('.')[0]) ?? 0;
    return version >= 33; // Android 13 = API level 33
  }



  Future<void> _scheduleNotification(DateTime scheduledTime, String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'default_channel_id',
      'Default Channel',
      channelDescription: 'Channel for scheduled notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      platformChannelSpecifics,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }





  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersString = prefs.getString('reminders') ?? '[]';
    final eventsString = prefs.getString('events') ?? '[]'; // Carica eventi
    setState(() {
      _reminders = List<Map<String, dynamic>>.from(jsonDecode(remindersString));
      _events = List<Map<String, dynamic>>.from(jsonDecode(eventsString)); // Inizializza eventi
    });
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('reminders', jsonEncode(_reminders));
    prefs.setString('events', jsonEncode(_events)); // Salva eventi
  }

  void _addReminder(TimeOfDay time, List<int> days) {
    final newReminder = {
      'time': time.format(context),
      'days': days,
    };
    setState(() {
      _reminders.add(newReminder);
    });
    _saveReminders();

    for (int day in days) {
      DateTime now = DateTime.now();
      DateTime reminderDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // funzione notifica per il repeat
      reminderDateTime = reminderDateTime.add(Duration(days: (day - now.weekday + 7) % 7));

      _scheduleNotification(
        reminderDateTime,
        'Reminder',
        'Promemoria alle ${time.format(context)} per il giorno selezionato',
      );
    }
  }


  void _addEvent(DateTime selectedDate, TimeOfDay selectedTime, String eventTitle) {
    final eventDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    final newEvent = {
      'title': eventTitle,
      'date': selectedDate.toIso8601String(),
      'time': selectedTime.format(context),
    };
    setState(() {
      _events.add(newEvent);
    });
    _saveReminders();


    _scheduleNotification(
      eventDateTime,
      'Evento: $eventTitle',
      'L\'evento "$eventTitle" è programmato per le ${selectedTime.format(context)}',
    );
  }

  void _deleteEvent(int index) {
    setState(() {
      _events.removeAt(index);
    });
    _saveReminders();
  }


  void _deleteReminder(int index) {
    setState(() {
      _reminders.removeAt(index);
    });
    _saveReminders();
  }

  void _showReminderDialog() {
    TimeOfDay selectedTime = TimeOfDay.now();
    List<int> selectedDays = [];
    List<bool> selectedChips = List.generate(7, (index) => false); // Stato delle chips

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Aggiungi Reminder'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Seleziona Orario'),
                    trailing: IconButton(
                      icon: Icon(Icons.access_time),
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          selectedTime = time;
                        }
                      },
                    ),
                  ),
                  Wrap(
                    children: List<Widget>.generate(7, (index) {
                      return ChoiceChip(
                        label: Text(['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'][index]),
                        selected: selectedChips[index],
                        selectedColor: Colors.red,
                        backgroundColor: Colors.grey[200],
                        onSelected: (selected) {
                          setState(() {
                            selectedChips[index] = selected;
                            if (selected) {
                              selectedDays.add(index);
                            } else {
                              selectedDays.remove(index);
                            }
                          });
                        },
                      );
                    }),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                _addReminder(selectedTime, selectedDays);
                Navigator.of(context).pop();
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void _showEventDialog() {
    String title = '';
    TimeOfDay selectedTime = TimeOfDay.now(); // Aggiungi orario selezionato

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            title: Text('Aggiungi Evento'),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) {
                        title = value;
                      },
                      decoration: InputDecoration(hintText: "Titolo dell'evento"),
                    ),
                    ListTile(
                      title: Text('Seleziona Orario'),
                      trailing: IconButton(
                        icon: Icon(Icons.access_time),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            selectedTime = time;
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            actions: [
            TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Annulla'),
            ),
              TextButton(
                onPressed: () {
                  if (title.isNotEmpty) {
                    _addEvent(_selectedDay ?? _focusedDay, selectedTime, title);
                  Navigator.of(context).pop();
                  }
                },
        child: Text('Salva'),
              ),
            ],
        );
      },
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Calendario'),
    ),
    body: Column(
      children: [
        Center(
          child: ToggleButtons(
            isSelected: [_isCalendarVisible, !_isCalendarVisible],
            onPressed: (index) {
              setState(() {
                _isCalendarVisible = index == 0; // 0 calendario visibile
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Calendario'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Reminder'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        Expanded(
          child: _isCalendarVisible ? _buildCalendarView() : _buildReminderView(),
        ),
      ],
    ),
    floatingActionButton: _isCalendarVisible
        ? IconButton(
      icon: const Icon(Icons.add), // Pulsante eventi
      onPressed: _showEventDialog,
      tooltip: 'Aggiungi Evento',
      style: ButtonStyle(

        foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
        backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
        shadowColor: WidgetStateProperty.all<Color>(Colors.red),
      ),
    )
        : IconButton(
      icon: const Icon(Icons.alarm_add), // Pulsante reminder
      onPressed: _showReminderDialog,
      tooltip: 'Aggiungi Reminder',
      style: ButtonStyle(

        foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
        backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
        shadowColor: WidgetStateProperty.all<Color>(Colors.red),
      ),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
  );
}

Widget _buildCalendarView() {
  return _buildCalendar();
}

Widget _buildReminderView() {
  return _buildReminderList();
}

Widget _buildCalendar() {
  return Column(
    children: [
      TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        calendarFormat: _calendarFormat,
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        calendarStyle: const CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            bool hasEvent = _events.any((event) {
              DateTime eventDate = DateTime.parse(event['date']);
              return eventDate.year == date.year &&
                  eventDate.month == date.month &&
                  eventDate.day == date.day;
            });

            return hasEvent
                ? Positioned(
              bottom: 1,
              right: 1,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue, // Colore del pallino
                  shape: BoxShape.circle,
                ),
              ),
            )
                : const SizedBox.shrink(); // Non mostrare nulla se non ci sono eventi
          },
        ),
      ),
      _buildEventsForSelectedDay(), // Mostra gli even ti per il giorno selezionato
    ],
  );
}

  Widget _buildEventsForSelectedDay() {
    if (_selectedDay == null) return SizedBox(); // Se non è selezionato, non mostrare nulla

    final eventsForSelectedDay = _events.where((event) {
      DateTime eventDate = DateTime.parse(event['date']);
      return eventDate.year == _selectedDay!.year &&
          eventDate.month == _selectedDay!.month &&
          eventDate.day == _selectedDay!.day;
    }).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(), // Non permettere lo scorrimento
      itemCount: eventsForSelectedDay.length,
      itemBuilder: (context, index) {
        final event = eventsForSelectedDay[index];
        return ListTile(
          title: Text(event['title']),
          subtitle: Text('Orario: ${event['time']}'),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              int globalIndex = _events.indexOf(event);
              _deleteEvent(globalIndex);
            },
          ),
        );
      },
    );
  }


  Widget _buildReminderList() {
    return ListView.builder(
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        final reminder = _reminders[index];
        final time = reminder['time'] as String;
        final days = (reminder['days'] as List<dynamic>).cast<int>();

        return ListTile(
          title: Text('Orario: $time'),
          subtitle: Text('Ripetizione: ${days.map((day) => ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'][day]).join(', ')}'),
          trailing: IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _deleteReminder(index);
            },
          ),
        );
      },
    );
  }
}
