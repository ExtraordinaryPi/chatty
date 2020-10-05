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
import 'WebMetaInfo.dart';

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
  String _oldString;
  WebMetaInfo _webMetaInfo = WebMetaInfo(null, null, null);
  final _metaInfoCacheMap = Map<int, WebMetaInfo>();

  Future<void> _checkHttp(String url, BuildContext context) async {
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _previewGate = true;
          _previewHeight = MediaQuery.of(context).size.height * 0.20;
        });
      } else {
        setState(() {
          _previewGate = false;
          _previewHeight = 0;
        });
      }
    } catch (e) {
      setState(() {
        _previewHeight = 0;
      });
      print(e);
    }
  }

  Widget _buildAppBar(BuildContext context) {
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

  Widget _buildChatList(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemBuilder: (BuildContext context, int index) {
          Color color = Colors.white;
          int mapIndex = _chatHistory.length - index - 1;
          if (_markedMessages.contains(index)) {
            color = Colors.yellow;
          }

          if (_metaInfoCacheMap.containsKey(mapIndex)) {
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
                child: Column(children: [
                  Row(
                    children: [
                      Container(
                        width: _metaInfoCacheMap[mapIndex].pictureOnly == false
                            ? MediaQuery.of(context).size.width * 0.15
                            : 200,
                        height: _metaInfoCacheMap[mapIndex].pictureOnly == false
                            ? MediaQuery.of(context).size.height * 0.10
                            : 100,
                        alignment: Alignment.topCenter,
                        child: _metaInfoCacheMap[mapIndex].image != null
                            ? Image.network(_metaInfoCacheMap[mapIndex].image)
                            : Text("Kein Bild"),
                      ),
                      Container(
                        width: _metaInfoCacheMap[mapIndex].pictureOnly == false
                            ? MediaQuery.of(context).size.width * 0.75
                            : 0,
                        height: _metaInfoCacheMap[mapIndex].pictureOnly == false
                            ? MediaQuery.of(context).size.height * 0.10
                            : 0,
                        child: _metaInfoCacheMap[mapIndex].title != null
                            ? Text(_metaInfoCacheMap[mapIndex].title)
                            : Text("Kein Titel"),
                      ),
                    ],
                  ),
                  Container(
                    width: _metaInfoCacheMap[mapIndex].pictureOnly == false
                        ? MediaQuery.of(context).size.width
                        : 0,
                    height: _metaInfoCacheMap[mapIndex].pictureOnly == false
                        ? MediaQuery.of(context).size.height * 0.10
                        : 0,
                    child: _metaInfoCacheMap[mapIndex].description != null
                        ? Text(_metaInfoCacheMap[mapIndex].description)
                        : Text("Keine Beschreibung"),
                  ),
                ]),
              ),
            );
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
            child: Bubble(color: color, child: Text(_chatHistory[index])),
          );
        },
        itemCount: _chatHistory.length,
        shrinkWrap: true,
        reverse: true,
      ),
    );
  }

  Widget _buildLinkPreview(BuildContext context) {
    return Container(
      height: _previewHeight,
      child: Column(children: [
        Row(
          children: [
            Container(
              width: _webMetaInfo.pictureOnly == false
                  ? MediaQuery.of(context).size.width * 0.20
                  : 200,
              height: _webMetaInfo.pictureOnly == false
                  ? MediaQuery.of(context).size.height * 0.10
                  : 100,
              alignment: Alignment.topCenter,
              child: _webMetaInfo.image != null
                  ? Image.network(_webMetaInfo.image)
                  : Text("Kein Bild"),
            ),
            Container(
              width: _webMetaInfo.pictureOnly == false
                  ? MediaQuery.of(context).size.width * 0.80
                  : 0,
              height: _webMetaInfo.pictureOnly == false
                  ? MediaQuery.of(context).size.height * 0.10
                  : 0,
              child: _webMetaInfo.title != null
                  ? Text(_webMetaInfo.title)
                  : Text("Kein Titel"),
            ),
          ],
        ),
        Container(
          width: _webMetaInfo.pictureOnly == false
              ? MediaQuery.of(context).size.width
              : 0,
          height: _webMetaInfo.pictureOnly == false
              ? MediaQuery.of(context).size.height * 0.10
              : 0,
          child: _webMetaInfo.description != null
              ? Text(_webMetaInfo.description)
              : Text("Keine Beschreibung"),
        ),
      ]),
    );
  }

  Widget _buildKeyboardBar(BuildContext context) {
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
              if (changedString != _oldString) {
                _oldString = changedString;
                if (changedString.startsWith("https://") ||
                    changedString.startsWith("http://")) {
                  _checkHttp(changedString, context);
                } else {
                  setState(() {
                    _previewGate = false;
                    _previewHeight = 0;
                  });
                }
              }
              if (_previewGate) {
                String url = changedString.toLowerCase();
                if (url.endsWith(".apng") ||
                    url.endsWith(".bmp") ||
                    url.endsWith(".gif") ||
                    url.endsWith(".ico") ||
                    url.endsWith(".jpeg") ||
                    url.endsWith(".png") ||
                    url.endsWith(".svg") ||
                    url.endsWith(".webp")) {
                  setState(() {
                    _webMetaInfo.getPicture(changedString);
                  });
                } else {
                  setState(() {
                    _webMetaInfo.getMetaInfo(changedString);
                  });
                }
              } else {
                _previewHeight = 0;
              }
            },
            onSubmitted: (chatText) {
              if (_previewHeight > 10) {
                setState(() {
                  _metaInfoCacheMap[_chatHistory.length] = _webMetaInfo.clone();
                  _previewHeight = 0;
                });
              }
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

  Widget _buildEmojiPicker(BuildContext context) {
    return Container(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          _buildChatList(context),
          Container(
              height: 50 + _previewHeight,
              color: Colors.green[50],
              child: Column(
                children: [
                  _buildLinkPreview(context),
                  _buildKeyboardBar(context)
                ],
              )),
          _buildEmojiPicker(context)
        ],
      ),
    );
  }
}
