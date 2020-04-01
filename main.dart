import 'dart:io' as io;
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'package:teledart/model.dart';
import 'package:beautifulsoup/beautifulsoup.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

Future<List<Uri>> getGoogleImages(String query, {int count = 5}) async {
  var url = Uri.parse(
      "https://www.google.com/search?tbm=isch&q=${Uri.encodeFull(query)}");
  var document = (await Dio().getUri(url)).data;
  var soup = Beautifulsoup(document);
  List<Uri> res = List();
  soup.find_all('img').forEach((elem) {
    if (elem.attributes['src'] != null) if (elem.attributes['src']
        .contains("gstatic.com")) {
      if (count == 0) return;
      count--;
      res.add(Uri.parse(elem.attributes['src']));
    }
  });
  return res;
}

void main() {
  var logFile = new io.File('usage.log');
  var teledart = TeleDart(
      Telegram(io.Platform.environment['TELEGRAM_API_TOKEN']), Event());

  teledart.start().then((me) => print('${me.username} is initialised.'));

  teledart.onCommand('greet').listen(((message) => teledart.replyMessage(
      message,
      'Hello, Sir ${message.from.first_name}${message.from.last_name == null ? "" : " " + message.from.last_name}!')));

  teledart
      .onMessage(keyword: 'dart')
      .where((message) => message.text.contains('telegram'))
      .listen((message) => teledart.replyPhoto(message,
          'https://raw.githubusercontent.com/DinoLeung/TeleDart/master/example/dash_paper_plane.png',
          caption: 'This is how the Dart Bird and Telegram, met'));

  teledart.onInlineQuery().listen((inlineQuery) => {
        logFile.writeAsString(
            "Incoming inline query \"" +
                inlineQuery.query +
                "\" from ${inlineQuery.from.first_name}${inlineQuery.from.last_name == null ? "" : " " + inlineQuery.from.last_name}\n",
            mode: io.FileMode.append),
        getGoogleImages(inlineQuery.query, count: 12).then((urls) {
          var results = new List<InlineQueryResult>();
          int count = 0;
          for (var url in urls) {
            count++;
            results.add(
              InlineQueryResultPhoto()
                ..caption = count.toString()
                ..thumb_url = url.toString()
                ..photo_url = url.toString()
                ..id = count.toString(),
            );
          }
          teledart.answerInlineQuery(inlineQuery, results);
        }),
      });

  logFile.stat().then((onValue) {
    if (onValue.size > 5000000) {
      logFile.delete();
      logFile.create();
    }
  });
}
