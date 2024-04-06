import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delegados App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
  List<Event> events = [];
  late FlutterSoundPlayer audioPlayer;

  @override
  void initState() {
    super.initState();
    audioPlayer = FlutterSoundPlayer();
    loadEvents();
  }

  @override
  void dispose() {
    audioPlayer.closePlayer();
    super.dispose();
  }

  Future<void> loadEvents() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/events.json');
    if (file.existsSync()) {
      final jsonData = await file.readAsString();
      setState(() {
        events = Event.decode(jsonData);
      });
    }
  }

  Future<void> saveEvents() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/events.json');
    await file.writeAsString(Event.encode(events));
  }

  void deleteAllEvents() {
    setState(() {
      events.clear();
    });
    saveEvents();
  }

  void addEvent(Event event) {
    setState(() {
      events.add(event);
    });
    saveEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delegados App'),
      ),
      body: ListView.builder(
        itemCount: events.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(events[index].title),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailsPage(
                      event: events[index], audioPlayer: audioPlayer),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return EventDialog(onSubmit: addEvent);
            },
          );
        },
        tooltip: 'Registrar Evento',
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.info),
              onPressed: () {
                // Implementar la sección "Acerca de"
              },
            ),
            IconButton(
              icon: Icon(Icons.security),
              onPressed: deleteAllEvents,
            ),
          ],
        ),
      ),
    );
  }
}

class Event {
  final String title;
  final String description;
  final String image;
  final String audio;
  final DateTime date;

  Event({
    required this.title,
    required this.description,
    required this.image,
    required this.audio,
    required this.date,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      title: json['title'],
      description: json['description'],
      image: json['image'],
      audio: json['audio'],
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'image': image,
        'audio': audio,
        'date': date.toIso8601String(),
      };

  static String encode(List<Event> events) =>
      jsonEncode(events.map((event) => event.toJson()).toList());

  static List<Event> decode(String jsonData) => (jsonDecode(jsonData) as List)
      .map((item) => Event.fromJson(item))
      .toList();
}

class EventDetailsPage extends StatelessWidget {
  final Event event;
  final FlutterSoundPlayer audioPlayer;

  EventDetailsPage({required this.event, required this.audioPlayer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Descripción: ${event.description}',
            ),
            SizedBox(height: 20),
            event.image.isNotEmpty
                ? Image.file(
                    File(event.image),
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  )
                : SizedBox(),
            SizedBox(height: 20),
            event.audio.isNotEmpty
                ? ElevatedButton(
                    onPressed: () async {
                      audioPlayer
                          .startPlayer(fromURI: event.audio)
                          .then((value) {
                        // Manejar el valor devuelto si es necesario
                      });
                    },
                    child: Text('Reproducir Audio'),
                  )
                : SizedBox(),
            SizedBox(height: 20),
            Text(
              'Fecha: ${event.date}',
            ),
          ],
        ),
      ),
    );
  }
}

class EventDialog extends StatefulWidget {
  final void Function(Event) onSubmit;

  EventDialog({required this.onSubmit});

  @override
  DialogState createState() => DialogState();
}

class DialogState extends State<EventDialog> {
  late String _title;
  late String _description;
  late String _imagePath;
  late String _audioPath;
  late DateTime _date;

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nuevo Evento'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Título'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese un título';
                  }
                  return null;
                },
                onSaved: (value) {
                  _title = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Descripción'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese una descripción';
                  }
                  return null;
                },
                onSaved: (value) {
                  _description = value!;
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.image,
                  );
                  if (result != null) {
                    setState(() {
                      _imagePath = result.files.single.path!;
                    });
                  }
                },
                child: Text('Seleccionar Imagen'),
              ),
              ElevatedButton(
                onPressed: () async {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.audio,
                  );
                  if (result != null) {
                    setState(() {
                      _audioPath = result.files.single.path!;
                    });
                  }
                },
                child: Text('Seleccionar Audio'),
              ),
              TextButton(
                onPressed: () async {
                  final DateTime? selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2025),
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: ThemeData.dark(),
                        child: child!,
                      );
                    },
                  );
                  if (selectedDate != null) {
                    setState(() {
                      _date = selectedDate;
                    });
                  }
                },
                child: Text('Seleccionar Fecha'),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              widget.onSubmit(Event(
                title: _title,
                description: _description,
                image: _imagePath,
                audio: _audioPath,
                date: _date,
              ));
              Navigator.of(context).pop();
            }
          },
          child: Text('Guardar'),
        ),
      ],
    );
  }
}
