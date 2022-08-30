import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:translator/translator.dart';

import 'stt_extension.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Translator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LocaleName? inputLanguage;
  LocaleName? outputLanguage;

  bool readyToListen = false;
  bool isListening = false;

  String recordedText = "";
  String translatedText = "";

  List<LocaleName> sttLocales = [];

  // Please use translator plugin for translation https://pub.dev/packages/translator
  final translator = GoogleTranslator();

  // Please use flutter_tts plugin to play the translated text with output language https://pub.dev/packages/flutter_tts
  FlutterTts textToSpeech = FlutterTts();
  SpeechToText speechToText = SpeechToText();

  Future<bool> initialize() async {
    await textToSpeech.awaitSpeakCompletion(true);
    return await speechToText.initialize(
      debugLogging: true,
    );
  }

  void _startListening() {
    if (readyToListen) {
      startListening();
      setState(() {
        isListening = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Voice recording not available..."),
        ),
      );
    }
  }

  Future<void> startListening() async {
    await speechToText.listen(
      onResult: _onSpeechResult,
      listenMode: ListenMode.dictation,
      pauseFor: const Duration(seconds: 5),
      localeId: inputLanguage?.localeId,
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) async {
    log("Recognized words ${result.recognizedWords}");
    setState(() {
      recordedText = result.recognizedWords;
      if (result.finalResult) {
        _stopListening();
      }
    });
  }

  void _stopListening() {
    log("stopping listening");
    speechToText.stop().then((value) => setState(() => isListening = false));
    _translate(recordedText);
  }

  void _translate(String text) async {
    translatedText = (await translator.translate(
      text,
      from: inputLanguage?.getTTSId() ?? "auto",
      to: outputLanguage?.getTTSId() ?? "en",
    ))
        .text;

    setState(() {});
  }

  void _speak(String text, LocaleName? outputLanguage) async {
    await textToSpeech.setLanguage(outputLanguage?.localeId ?? "en_US");
    await textToSpeech
        .speak(text)
        .catchError((error)=>log(error))
        .timeout(const Duration(minutes: 3));
    await textToSpeech.stop();
  }

  @override
  void initState() {
    super.initState();
    initialize().then(
      (value) => setState(
        () {
          readyToListen = value;
          speechToText.locales().then((locales) => sttLocales = locales);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            DropdownButton<LocaleName>(
              items: sttLocales
                  .map<DropdownMenuItem<LocaleName>>(
                    (e) => DropdownMenuItem(child: Text(e.name), value: e),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                setState(() {
                  inputLanguage = value;
                });
              },
              value: inputLanguage,
              hint: const Text("Select input language"),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (recordedText.isNotEmpty)
                  IconButton(
                      onPressed: () async {
                        _speak(recordedText, inputLanguage);
                      },
                      icon: const Icon(Icons.play_arrow)),
                Flexible(
                  child: Text(
                    recordedText,
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                ),
              ],
            ),
            DropdownButton<LocaleName>(
              items: sttLocales
                  .map<DropdownMenuItem<LocaleName>>(
                    (e) => DropdownMenuItem(child: Text(e.name), value: e),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                setState(() {
                  outputLanguage = value;
                });
                _translate(recordedText);
              },
              value: outputLanguage,
              hint: const Text("Select output language"),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (translatedText.isNotEmpty)
                  IconButton(
                      onPressed: () {
                        _speak(translatedText, outputLanguage);
                      },
                      icon: const Icon(Icons.play_arrow)),
                Flexible(
                  child: Text(
                    translatedText,
                    style: Theme.of(context).textTheme.bodyText1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: !isListening ? _startListening : _stopListening,
        tooltip: 'start',
        child: !isListening
            ? const Icon(Icons.fiber_manual_record)
            : const Icon(Icons.stop),
      ),
    );
  }
}
