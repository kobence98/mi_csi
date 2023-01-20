import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class Session {
  Map<String, String> headers = {};

  String domainName = 'http://164.90.230.81:8088';
  // String domainName = 'http://10.0.2.2:8088';

  Future<dynamic> get(String url) async {
    http.Response response =
        await http.get(Uri.parse(domainName + url), headers: headers);
    updateCookie(response);
    return response;
  }

  Future<dynamic> postLogin(String url, dynamic data) async {
    headers.clear();
    http.Response response = await http.post(Uri.parse(domainName + url),
        body: data, headers: headers);
    updateCookie(response);
    return response;
  }

  Future<dynamic> post(String url, dynamic data) async {
    headers.remove('Content-type');
    http.Response response = await http.post(Uri.parse(domainName + url),
        body: data, headers: headers);
    updateCookie(response);
    return response;
  }

  Future<dynamic> postJson(String url, dynamic data) async {
    Map<String, String> newHeaders = headers;
    newHeaders.addAll({'Content-type': 'application/json'});
    http.Response response = await http.post(Uri.parse(domainName + url),
        body: jsonEncode(data), headers: headers);
    updateCookie(response);
    return response;
  }

  Future<dynamic> postDomainJson(String url, Map<String, String?> data) async {
    data.addAll({'domain': domainName});
    Map<String, String> newHeaders = headers;
    newHeaders.addAll({'Content-type': 'application/json'});
    http.Response response = await http.post(Uri.parse(domainName + url),
        body: jsonEncode(data), headers: headers);
    updateCookie(response);
    return response;
  }

  void updateCookie(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      int index = rawCookie.indexOf(';');
      headers['cookie'] =
          (index == -1) ? rawCookie : rawCookie.substring(0, index);
    }
  }

  Future<dynamic> sendMultipart(
      String url, Map<String, String> params, Uint8List bytes) async {
    var request =
        http.MultipartRequest("POST", Uri.parse(domainName + url));
    params.forEach((key, value) {
      request.fields[key] = value;
    });

    request.files.add(http.MultipartFile.fromBytes(
        'multipartImage', List.from(bytes),
        filename: 'multipartImage'));

    Map<String, String> newHeaders = headers;
    newHeaders.addAll({'Content-type': 'application/json'});
    request.headers.addAll(newHeaders);
    return await request.send();
  }

  Future<dynamic> delete(String url) async {
    headers.remove('Content-type');
    http.Response response = await http.delete(Uri.parse(domainName + url),
        body: <String, dynamic>{}, headers: headers);
    updateCookie(response);
    return response;
  }
}
