import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';


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
    _selectedDay = _focusedDay;
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
        _openAppSettings();
      }
    }
  }

  void _openAppSettings() async {
    const url = 'app-settings:';
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
    final eventsString = prefs.getString('events') ?? '[]';
    setState(() {
      _reminders = List<Map<String, dynamic>>.from(jsonDecode(remindersString));
      _events = List<Map<String, dynamic>>.from(jsonDecode(eventsString));
    });
  }

  Future<void> _saveReminders() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('reminders', jsonEncode(_reminders));
    prefs.setString('events', jsonEncode(_events));
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

      // funzione notifica repeat
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
    String eventTitle = _events[index]['title'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Conferma eliminazione'),
          content: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                const TextSpan(text: 'Sei sicuro di voler eliminare l\'evento '),
                TextSpan(
                  text: eventTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _events.removeAt(index);
                });
                _saveReminders();
                Navigator.of(context).pop();
              },
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );
  }

  void _editEvent(int index) {
    String eventTitle = _events[index]['title'];
    String currentTimeString = _events[index]['time'];
    List<String> parts = currentTimeString.split(':');
    int currentHour = int.parse(parts[0]);
    int currentMinute = int.parse(parts[1]);
    TimeOfDay selectedTime = TimeOfDay(hour: currentHour, minute: currentMinute);

    TextEditingController titleController = TextEditingController(text: eventTitle);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifica Evento'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      onChanged: (value) {
                        eventTitle = value;
                      },
                      decoration: const InputDecoration(hintText: "Titolo dell'evento"),
                    ),
                    ListTile(
                      title: const Text('Seleziona Orario'),
                      trailing: IconButton(
                        icon: const Icon(Icons.access_time_rounded),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setState(() {
                              selectedTime = time;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                if (eventTitle.isNotEmpty) {
                  _updateEvent(index, selectedTime, eventTitle);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }


  void _updateEvent(int index, TimeOfDay time, String title) {
    final eventDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      time.hour,
      time.minute,
    );

    final updatedEvent = {
      'title': title,
      'date': _selectedDay!.toIso8601String(),
      'time': time.format(context),
    };

    setState(() {
      _events[index] = updatedEvent;
    });

    _saveReminders();

    _scheduleNotification(
      eventDateTime,
      'Evento: $title',
      'L\'evento "$title" è programmato per le ${time.format(context)}',
    );
  }



  void _deleteReminder(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Conferma eliminazione'),
          content: const Text('Sei sicuro di voler eliminare questo reminder?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _reminders.removeAt(index);
                });
                _saveReminders();
                Navigator.of(context).pop();
              },
              child: const Text('Elimina'),
            ),
          ],
        );
      },
    );
  }


  void _editReminder(int index) {
    String currentTimeString = _reminders[index]['time'];
    List<String> parts = currentTimeString.split(':');
    int currentHour = int.parse(parts[0]);
    int currentMinute = int.parse(parts[1]);
    TimeOfDay selectedTime = TimeOfDay(hour: currentHour, minute: currentMinute);

    List<int> selectedDays = _reminders[index]['days'].cast<int>();
    List<bool> selectedChips = List.generate(7, (index) => selectedDays.contains(index));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifica Reminder'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Seleziona Orario'),
                    trailing: IconButton(
                      icon: const Icon(Icons.access_time_rounded),
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
                        selectedColor: Colors.red[400],
                        backgroundColor: Colors.transparent,
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
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                _updateReminder(index, selectedTime, selectedDays);
                Navigator.of(context).pop();
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  void _updateReminder(int index, TimeOfDay time, List<int> days) {
    final updatedReminder = {
      'time': time.format(context),
      'days': days,
    };
    setState(() {
      _reminders[index] = updatedReminder;
    });
    _saveReminders();

    _rescheduleNotifications(index, time, days);
  }


  void _rescheduleNotifications(int index, TimeOfDay time, List<int> days) {
    for (int day in days) {
      DateTime now = DateTime.now();
      DateTime reminderDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      reminderDateTime = reminderDateTime.add(Duration(days: (day - now.weekday + 7) % 7));

      _scheduleNotification(
        reminderDateTime,
        'Reminder',
        'Promemoria aggiornato alle ${time.format(context)} per il giorno selezionato',
      );
    }
  }



  void _showReminderDialog() {
    TimeOfDay selectedTime = TimeOfDay.now();
    List<int> selectedDays = [];
    List<bool> selectedChips = List.generate(7, (index) => false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Aggiungi Reminder'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Seleziona Orario'),
                    trailing: IconButton(
                      icon: const Icon(Icons.access_time_rounded),
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
                        selectedColor: Colors.red[400],
                        backgroundColor: Colors.transparent,
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
              child: const Text('Annulla'),
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
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Aggiungi Evento'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) {
                        title = value;
                      },
                      decoration: const InputDecoration(hintText: "Titolo dell'evento"),
                    ),
                    ListTile(
                      title: const Text('Seleziona Orario'),
                      trailing: IconButton(
                        icon: const Icon(Icons.access_time_rounded),
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setState(() {
                              selectedTime = time;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () {
                if (title.isNotEmpty) {
                  _addEvent(_selectedDay ?? _focusedDay, selectedTime, title);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
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
          locale: 'it_IT',
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Mese'},
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
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
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
              )
                  : const SizedBox.shrink();
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime.now();
                  _selectedDay = DateTime.now();
                });
              },
              child: const Text('Oggi'),
            ),
          ],
        ),
        _buildEventsForSelectedDay(),
      ],
    );
  }




  Widget _buildEventsForSelectedDay() {
    if (_selectedDay == null) return const SizedBox();

    final eventsForSelectedDay = _events.where((event) {
      DateTime eventDate = DateTime.parse(event['date']);
      return eventDate.year == _selectedDay!.year &&
          eventDate.month == _selectedDay!.month &&
          eventDate.day == _selectedDay!.day;
    }).toList();

    return Expanded(
      child: ListView.builder(
        itemCount: eventsForSelectedDay.length,
        itemBuilder: (context, index) {
          final event = eventsForSelectedDay[index];
          return ListTile(
            title: Text(
              event['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Orario: ${event['time']}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_rounded, color: Colors.red),
              onPressed: () {
                int globalIndex = _events.indexOf(event);
                _deleteEvent(globalIndex);
              },
            ),
            onTap: () {
              _editEvent(index);
            },
          );
        },
      ),
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
          title: Text(''
              'Orario: $time',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Ripetizione: ${days.map((day) => ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'][day]).join(', ')}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_rounded, color: Colors.red),
            onPressed: () {
              _deleteReminder(index);
            },
          ),
          onTap: () {
            _editReminder(index);
          },
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
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
              isSelected: [_isCalendarVisible, !_isCalendarVisible],
              onPressed: (index) {
                setState(() {
                  _isCalendarVisible = index == 0; // 0= calendario visibile
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
        icon: const Icon(Icons.add_rounded),
        onPressed: _showEventDialog,
        tooltip: 'Aggiungi Evento',
        style: ButtonStyle(

          foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
          backgroundColor: WidgetStateProperty.all<Color>(Colors.red),
          shadowColor: WidgetStateProperty.all<Color>(Colors.red),
        ),
      )
          : IconButton(
        icon: const Icon(Icons.alarm_add_rounded),
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


}
