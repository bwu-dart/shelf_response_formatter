library shelf_response_formatter;

import 'package:shelf/shelf.dart' as shelf;
import 'dart:convert';
import 'xml_converter.dart';

typedef String Formatter(dynamic data);

class ResponseFormatter {
  /// Map of accept headers to response formats.
  Map<String, String> acceptMappings = {
    "application/xml": "xml",
    "application/xhtml+xml": "xml",
    "text/html": "xml",
    "application/json": "json",
    "text/json": "json",
    "text/plain": "text",
    "*/*": "text"
  };

  /// Map of response formats to formatter functions.
  Map<String, Formatter> formatterMappings = {
    "xml": xmlFormatter,
    "json": jsonFormatter,
    "text": textFormatter
  };

  /// Map of response formats to formatter functions.
  Map<String, String> responseFormatMappings = {
    "xml": "application/xml",
    "json": "application/json",
    "text": "text/plain"
  };

  /// Register an additional formatter Function with identifier name (eg.: csv).
  /// An optional list of accept-headers can be provided the should be handled
  /// by this formatter.
  registerFormatter(name, contentType, Formatter formatter, [List handles]) {
    formatterMappings[name] = formatter;
    acceptMappings[contentType] = name;
    responseFormatMappings[name] = contentType;
    if (handles != null) {
      handles.forEach((handle) {
        acceptMappings[handle] = name;
      });
    }
  }

  /// Singleton constructor
  factory ResponseFormatter() {
    if (instance == null) {
      instance = new ResponseFormatter._create();
    }
    return instance;
  }

  // private constructor
  ResponseFormatter._create();
  static ResponseFormatter instance;

  /// Detects the requested format and returns a response [String] with the data
  /// encoded appropriately.
  FormatResult formatResponse(shelf.Request request, dynamic data) {
    var format = findTargetFormat(request);
    return new FormatResult(
        formatterMappings[format](data), responseFormatMappings[format]);
  }

  /// Given a [shelf.Request] this method tries to find the best format in which
  /// to return the response body to the client. It first looks for a format
  /// param in the requests query string (eg.: /path?format=json).
  ///
  /// If no query param is present or no [Formatter] could be found for the
  /// format the method looks for a file extension with a known format
  /// (eg.: /path.xml).
  ///
  /// Lastly all the accept headers of the request are checked if one is present
  /// in accept mappings.
  ///
  /// If no response formatter could be found the response format is switched to
  /// text.
  String findTargetFormat(shelf.Request request) {
    String path = request.requestedUri.path;
    String queryFormat = request.requestedUri.queryParameters['format'];
    String acceptHeaders = request.headers['accept'];

    // from query string format param
    if (queryFormat != null && formatterMappings.containsKey(queryFormat)) {
      return queryFormat;
    }

    // from path file extension
    if (path.lastIndexOf('.') != -1 &&
        path.lastIndexOf('.') + 1 < path.length) {
      var fileFormat = path.substring(path.lastIndexOf('.') + 1);
      if (formatterMappings.containsKey(fileFormat)) {
        return fileFormat;
      }
    }

    // from accept header
    List<String> accepts = _parseAcceptHeaders(acceptHeaders);
    String accepted =
        accepts.firstWhere((accept) => acceptMappings.containsKey(accept));
    return acceptMappings[accepted];
  }

  /// Parses the accept headers of a request into a String list.
  List<String> _parseAcceptHeaders(String accepts) {
    if (!(accepts is String)) return ["*/*"];

    List<String> result = [];
    List<String> acceptList = accepts.split(',');

    acceptList.forEach((accept) {
      if (accept.contains(';q=')) {
        accept = accept.substring(0, accept.indexOf(';'));
      }
      result.add(accept);
    });
    if (!result.contains("*/*")) result.add("*/*");
    return result;
  }
}

/// Result container for the ResponseFormatter. Contains the [String] result of
/// the encoder and a contentType suggestion for the response header.
class FormatResult {
  String contentType;
  String body;

  FormatResult(this.body, this.contentType);
}

/// Encodes the response data as Json
String jsonFormatter(data) {
  return json.encode(data, toEncodable: (dynamic obj) {
    return obj.toString();
  });
}

/// Encodes the response data as XML
String xmlFormatter(data) {
  return new XmlConverter().convert(data);
}

/// Simple fallback text formatter looking for a message field in the
String textFormatter(data) {
  if (data != null && data is Map && data.containsKey("message")) {
    return data["message"];
  }
  return "";
}
