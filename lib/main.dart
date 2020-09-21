// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:bubble/bubble.dart';
import 'package:emoji_picker/emoji_picker.dart';
import 'package:flutter/services.dart';
import 'package:share/share.dart';
import 'package:flutter_link_preview/flutter_link_preview.dart';
import 'package:http/http.dart' as http;
import 'package:metadata_fetch/metadata_fetch.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        // Add the 3 lines from here...
        primaryColor: Colors.white,
      ), // ... to here.
      home: RandomWords(),
    );
  }
}

class RandomWords extends StatefulWidget {
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _saved = Set<WordPair>();
  final _biggerFont = TextStyle(fontSize: 18.0);
  final _chatHistory = List<String>();
  final _entry = GlobalKey<FormState>();
  final myController = TextEditingController();
  final appBarHeight = AppBar(
    title: Text('Chatty'),
  ).preferredSize.height;
  bool _showEmojis = false;
  double _emojiPickerHeight = 0;
  final _markedMessages = List<int>();
  double _previewHeight = 0;
  RegExp regExp = new RegExp(
    r"_^(?:(?:https?|ftp)://)(?:\S+(?::\S*)?@)?(?:(?!10(?:\.\d{1,3}){3})(?!127(?:\.\d{1,3}){3})(?!169\.254(?:\.\d{1,3}){2})(?!192\.168(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\x{00a1}-\x{ffff}0-9]+-?)*[a-z\x{00a1}-\x{ffff}0-9]+)(?:\.(?:[a-z\x{00a1}-\x{ffff}0-9]+-?)*[a-z\x{00a1}-\x{ffff}0-9]+)*(?:\.(?:[a-z\x{00a1}-\x{ffff}]{2,})))(?::\d{2,5})?(?:/[^\s]*)?$_iuS",
    caseSensitive: false,
    multiLine: false,
  );

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemBuilder: /*1*/ (context, i) {
          if (i.isOdd) return Divider();
          /*2*/

          final index = i ~/ 2; /*3*/
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10)); /*4*/
          }
          return _buildRow(_suggestions[index]);
        });
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        // NEW from here...
        alreadySaved ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved ? Colors.red : null,
      ),
      onTap: () {
        // NEW lines from here...
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
          } else {
            _saved.add(pair);
          }
        });
      }, // ... to here.
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // NEW lines from here...
        builder: (BuildContext context) {
          final tiles = _saved.map(
            (WordPair pair) {
              return ListTile(
                title: Text(
                  pair.asPascalCase,
                  style: _biggerFont,
                ),
              );
            },
          );
          final divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList();

          return Scaffold(
            appBar: AppBar(
              title: Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        }, // ...to here.
      ),
    );
  }

  _superTest(String chatText, int index) {
    RegExp regExp = new RegExp(
      r"((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)",
      caseSensitive: false,
      multiLine: false,
    );

    if (regExp.hasMatch(chatText)) {
      return FlutterLinkPreview(
        url: chatText,
        titleStyle: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      return Text(_chatHistory[index]);
    }
  }

  void _getHttpTest() async {
    try {
      var data = await extract(
          "https://strato.de/"); // Use the extract() function to fetch data from the url
      print(data.image);
    } catch (e){
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: 'Copy',
            onPressed: () {
              String copyString = "";
              _markedMessages.forEach(
                  (i) => copyString = copyString + _chatHistory[i] + " ");
              Clipboard.setData(ClipboardData(text: copyString));
              setState(() {
                _markedMessages.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () {
              String shareString = "";
              _markedMessages.forEach(
                  (i) => shareString = shareString + _chatHistory[i] + " ");
              Share.share(shareString);
              setState(() {
                _markedMessages.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Copy',
            onPressed: () {
              setState(() {
                _markedMessages.clear();
                _chatHistory.clear();
              });
            },
          ),
        ],
        title: Text('Chatty'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              itemBuilder: (BuildContext context, int index) {
                Color color = Colors.white;
                if (_markedMessages.contains(index)) {
                  color = Colors.yellow;
                }
                return GestureDetector(
                  onLongPress: () {
                    if (_markedMessages.contains(index)) {
                      setState(() {
                        _markedMessages.remove(index);
                      });
                    } else {
                      setState(() {
                        _markedMessages.add(index);
                      });
                    }
                  },
                  child: Bubble(
                      color: color,
                      child: _superTest(_chatHistory[index], index)),
                  //Text(_chatHistory[index]) _chatHistory
                  //    .map((message) => Bubble(child: Text(message)))
                  //    .toList(),
                );
              },
              itemCount: _chatHistory.length,
              shrinkWrap: true,
              reverse: true,
            ),
          ),
          Container(
              height: 50 + _previewHeight,
              color: Colors.green[50],
              child: Column(
                children: [
                  Container(
                    height: _previewHeight,
                    child: null
                  ),
                  Row(children: [
                    Container(
                        width: 100,
                        color: Colors.red[50],
                        child: TextField(
                          onTap: () {
                            setState(() {
                              _emojiPickerHeight = 0;
                              _showEmojis = false;
                            });
                          },
                          controller: myController,
                          onChanged: (changedString) {
                            if (regExp.hasMatch(changedString)) {
                              setState(() {
                                _previewHeight = 120;
                              });
                            } else {
                              setState(() {
                                _previewHeight = 0;
                              });
                            }
                          },
                          onSubmitted: (chatText) {
                            _getHttpTest();
                            setState(() {
                              _chatHistory.insert(0, chatText);
                            });
                            myController.clear();
                          },
                        )),
                    FlatButton(
                      onPressed: () {
                        setState(() {
                          _showEmojis = !(_showEmojis);
                        });
                        if (_showEmojis == true) {
                          setState(() {
                            _emojiPickerHeight = 211;
                          });
                        } else {
                          setState(() {
                            _emojiPickerHeight = 0;
                          });
                        }
                        FocusScopeNode currentFocus = FocusScope.of(context);

                        if (!currentFocus.hasPrimaryFocus) {
                          currentFocus.unfocus();
                          setState(() {});
                        }
                      },
                      child: Text(
                        "Emotes",
                      ),
                    )
                  ]),
                ],
              )),
          Container(
            height: _emojiPickerHeight,
            child: EmojiPicker(
              rows: 3,
              columns: 7,
              recommendKeywords: ["racing", "horse"],
              numRecommended: 10,
              onEmojiSelected: (emoji, category) {
                myController.text = myController.text + emoji.emoji;
              },
            ),
          )
        ],
      ),
    );
  }
}
