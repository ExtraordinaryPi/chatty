

import 'package:metadata_fetch/metadata_fetch.dart';


class WebMetaInfo {
  String title;
  String image;
  String description;

  WebMetaInfo(this.title, this.image, this.description);

  WebMetaInfo webMetaInfoConstructor(Metadata data){
  this.title = data.title;
  this.image = data.image;
  this.description = data.description;
  return this;
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

}

