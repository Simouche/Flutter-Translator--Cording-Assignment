import 'dart:developer';
import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:translator/translator.dart';
import 'package:speech_to_text/speech_to_text.dart' ;

String inputLanguageStt = "en_US";
String outputLanguageStt = "es_ES";

String inputLanguageTts = "en-US";
String outputLanguageTts = "es-ES";

String inputLanguageTranslatorFormat = "en";
String outputLanguageTranslatorFormat = "es";

String sttStatus = "";

bool loading = false;
bool enableSwitch = true;

// Please use translator plugin for translation https://pub.dev/packages/translator
final translator = GoogleTranslator();

// Please use flutter_tts plugin to play the translated text with output language https://pub.dev/packages/flutter_tts
FlutterTts textToSpeech = FlutterTts();
SpeechToText speechToText = SpeechToText();

Future<bool> initialize() async {
    await textToSpeech.awaitSpeakCompletion(true);
   return await speechToText.initialize(
      onError: _errorListener,
      onStatus: _statusListener,
      debugLogging: true,
    );
}

void _statusListener(String status) {
    sttStatus = status;
}


Future<void> startListening() async {
    // setState(() => loading=true);
    try {
      if(Platform.isIOS) {
        textToSpeech.stop();
      }
      else {
        await textToSpeech.stop();
      }
    } catch (e) {
      log(e.toString());
    }
    await speechToText.listen(
      onDevice: false,
      pauseFor: const Duration(seconds: 2),
      listenFor: null,
      localeId: inputLanguageStt,
      onSoundLevelChange: null,
      onResult: _onSpeechResult,
      partialResults: true,
      cancelOnError: false,
    );
    // setState(() => loading=false);
}

void _onSpeechResult(SpeechRecognitionResult result) async {
    String recognized = result.recognizedWords;
    String outputToSpeak = (await translator.translate(
      recognized,
      from: inputLanguageTranslatorFormat,
      to: outputLanguageTranslatorFormat,
    )).text;
    print("Recognized words ${result.recognizedWords}");
    if (result.finalResult ||
        (sttStatus == 'notListening' &&
            result.recognizedWords.length.toInt() != 0)) {
      // setState(()=>enableSwitch = false);
      await speechToText.stop();
      await textToSpeech.setLanguage(
        outputLanguageTts,
      );
      await textToSpeech
        .speak(outputToSpeak)
        .catchError(print)
        .timeout(const Duration(minutes: 3));
      await Future.delayed(const Duration(seconds: 2));
      // setState(() => loading=true);
      recognized = '';
      // startListening();
      // setState(() => loading=false);
      // setState(()=>enableSwitch = true);
    }
}

void _errorListener(SpeechRecognitionError error) async {
    log(error.errorMsg, name: "ERROR");
    if (error.errorMsg == 'error_no_match' ||
        error.errorMsg == "error_speech_timeout") {
      // setState(() => loading=true);
      await speechToText.stop();
      await speechToText.listen(
        onResult: _onSpeechResult,
        pauseFor: const Duration(seconds: 2),
        listenFor: null,
        onSoundLevelChange: null,
        cancelOnError: false,
        partialResults: true,
        localeId: inputLanguageStt,
      );
      // setState(() => loading=false);
    } else if (error.errorMsg == "error_busy") {
      // setState(() => loading=true);
      if(Platform.isIOS) {
        speechToText.stop();
      } else {
        await speechToText.stop();
      }
      await speechToText.listen(
        onResult: _onSpeechResult,
        pauseFor: const Duration(seconds: 2),
        listenFor: null,
        onSoundLevelChange: null,
        cancelOnError: false,
        partialResults: true,
        localeId: inputLanguageStt,
      );
      // setState(() => loading=false);
    } else if (error.errorMsg == "error_network") {
      // Helper.errorToast(
      //   context,
      //   "Please verify your internet connection before start using the service",
      //   const Duration(seconds: 3),
      // );
      await Future.delayed(const Duration(seconds: 3));
      await speechToText.stop();
      await speechToText.listen(
        onResult: _onSpeechResult,
        pauseFor: const Duration(seconds: 2),
        listenFor: null,
        onSoundLevelChange: null,
        cancelOnError: false,
        partialResults: true,
        localeId: inputLanguageStt,
      );
      // setState(() => loading=false);
    } else if (error.errorMsg == "error_retry") {
      // setState(() => loading=true);
      if(Platform.isIOS) {
        speechToText.stop();
      } else {
        await speechToText.stop();
      }
      await speechToText.listen(
        onResult: _onSpeechResult,
        pauseFor: const Duration(seconds: 2),
        listenFor: null,
        onSoundLevelChange: null,
        cancelOnError: false,
        partialResults: true,
        localeId: inputLanguageStt,
      );
      // setState(() => loading=false);
    }
    if(Platform.isIOS) {
      if(error.errorMsg == "error_unknown (7)" || error.errorMsg == "error_unknown (4)" || error.errorMsg == "error_unknown (209)") {
        // Helper.errorToast(
        //   context,
        //   "Something went wrong with translation process, please try later!",
        //   const Duration(seconds: 10),
        // );
      }
    }
  }

Future<void> switchLanguages() async {
    // setState(()=>enableSwitch = false);
    if(Platform.isIOS) {
        speechToText.stop();
    } else {
        await speechToText.cancel();
        await speechToText.stop();
    }

    String tmp = inputLanguageStt;
    inputLanguageStt = outputLanguageStt;
    outputLanguageStt = tmp;

    tmp = inputLanguageTts;
    inputLanguageTts = outputLanguageTts;
    outputLanguageTts = tmp;

    tmp = inputLanguageTranslatorFormat;
    inputLanguageTranslatorFormat = outputLanguageTranslatorFormat;
    outputLanguageTranslatorFormat = tmp;

    await startListening();
    // setState(()=>enableSwitch = true);
  }
