// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
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
  final _chatHistory = List<String>();
  final myController = TextEditingController();
  final appBarHeight = AppBar(
    title: Text('Chatty'),
  ).preferredSize.height;
  bool _showEmojis = false;
  double _emojiPickerHeight = 0;
  final _markedMessages = List<int>();
  double _previewHeight = 0;
  bool _previewGate = false;
  String _linkTitle = "";
  String _linkImage;
  RegExp regExp = new RegExp(
    r"((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)",
    caseSensitive: false,
    multiLine: false,
  );
  String _oldString;


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

  void _getHttpTest(String url) async {
    try {
      var data = await extract(url); // Use the extract() function to fetch data from the url
      setState(() {
        _linkTitle = data.title;
        _linkImage = data.image;

        _previewHeight = 120;
      });
    } catch (e){
      setState(() {
        _previewHeight = 0;
      });
      print(e);
    }
  }

  Future<void> _checkHttp(String url) async {
    try{
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _previewGate = true;
        });
      } else {
        setState(() {
          _previewGate = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Widget _buildAppBar(BuildContext context){
    return AppBar(
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
          tooltip: 'Clear Chat',
          onPressed: () {
            setState(() {
              _markedMessages.clear();
              _chatHistory.clear();
            });
          },
        ),
      ],
      title: Text('Chatty'),
    );
  }

  Widget _buildChatList(BuildContext context){
    return Expanded(
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
          );
        },
        itemCount: _chatHistory.length,
        shrinkWrap: true,
        reverse: true,
      ),
    );
  }

  Widget _buildLinkPreview(BuildContext context){
    return Container(
      height: _previewHeight,
      child: Row(
          children: [Container(
            width: 50,
            height: 50,
            child: _linkImage != null ? Image.network(_linkImage) : Text("Kein Bild"),
          ),Container(
            width: 100,
            child: _linkTitle != null ? Text(_linkTitle) : Text("Kein Titel"),
          ),
          ]),
    );
  }

  Widget _buildKeyboardBar(BuildContext context){
    return Row(children: [
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
              if(changedString != _oldString){
                _oldString = changedString;
                if(changedString.startsWith("https://") || changedString.startsWith("http://")){
                  _checkHttp(changedString);
                } else {
                  setState(() {
                    _previewGate = false;
                    _previewHeight = 0;
                  });
                }
              }
              if (_previewGate) {
                _getHttpTest(changedString);
              }
            },
            onSubmitted: (chatText) {
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
    ]);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[_buildChatList(context),
          Container(
              height: 50 + _previewHeight,
              color: Colors.green[50],
              child: Column(
                children: [
                  _buildLinkPreview(context),
                  _buildKeyboardBar(context)
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
