

import 'package:flutter/material.dart';
import 'package:metadata_fetch/metadata_fetch.dart';


class WebMetaInfo {
  String title;
  String image;
  String description;
  bool pictureOnly;

  WebMetaInfo(this.title, this.image, this.description);

  WebMetaInfo webMetaInfoConstructor(Metadata data){
  this.title = data.title;
  this.image = data.image;
  this.description = data.description;
  this.pictureOnly = false;
  return this;
  }

  WebMetaInfo clone(){
    WebMetaInfo webMetaInfo = new WebMetaInfo(this.title, this.image, this.description);
    webMetaInfo.title = this.title;
    webMetaInfo.pictureOnly = this.pictureOnly;
    webMetaInfo.description = this.description;
    webMetaInfo.image = this.image;
    return webMetaInfo;
  }

  Future<WebMetaInfo> getMetaInfo(String url) async{
    try {
      var data = await extract(url); // Use the extract() function to fetch data from the url
      return webMetaInfoConstructor(data);
    } catch (e) {
      print(e);
      return WebMetaInfo(null, null, null);
    }
  }

  WebMetaInfo getPicture(String url) {
    this.image = url;
    this.pictureOnly = true;
    return this;
  }
}

