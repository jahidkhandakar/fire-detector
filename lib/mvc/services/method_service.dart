import 'dart:convert';
import 'package:http/http.dart' as http;

class MethodService {
  //*_____________________POST___________________________//
  Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async{
    try{
      final uri = Uri.parse(url);
      final payload = jsonEncode(body);
      final response = await http.post(
        uri,
        body: payload
      );
      if(response.statusCode == 201){
        return {
          "statusCode": response.statusCode,
          "data": jsonDecode(response.body)
        };
      }else{
        return {
          "statusCode": response.statusCode,
          "data": jsonDecode(response.body)
        };
      }
    }catch(e){
      print("Error: ${e.toString()}");
      throw Exception("Failed to post data: ${e.toString()}");
    }
  }

  //*_____________________GET___________________________//
  Future<Map<String, dynamic>> get(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return {
          "statusCode": response.statusCode,
          "data": jsonDecode(response.body)
        };
      } else {
        return {
          "statusCode": response.statusCode,
          "data": jsonDecode(response.body)
        };
      }
    } catch (e) {
      print("Error: ${e.toString()}");
      throw Exception("Failed to get data: ${e.toString()}");
    }
  }
}