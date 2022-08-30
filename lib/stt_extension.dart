import 'package:speech_to_text/speech_to_text.dart';

extension LocalIdTTS on LocaleName{
  String getTTSId(){
    return localeId.split("_").first;
  }
}
