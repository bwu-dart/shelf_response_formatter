library shelf_response_formatter.xml_converter;

import 'package:xml/xml.dart';

/// Creates an XML String from a given simple data structure consisting of
/// [String], [num], [bool], [Map] and [List].
/// [Map] and [List] are iterated recursively all other types are added as text
/// nodes calling toString.
class XmlConverter {
  /// Convert method takes data a returns it as XML [String]
  String convert([dynamic data]) {
    return toXml(data).toXmlString(pretty: true);
  }

  /// Converts given data into an [XmlElement].
  XmlElement toXml([dynamic data]) {
    var builder = new XmlBuilder();
//    builder.processing('xml', 'version="1.0"');
    builder.element('response', nest: () => _createNode(builder, data));
    return builder.build().firstChild;
  }

  // internal recursive converter
  void _createNode(XmlBuilder builder, dynamic data) {
    if (data == null) return;

    if (data is Iterable) {
      data
          .map((item) =>
              builder.element('item', nest: () => _createNode(builder, item)))
          .toList(growable: false);
      return;
    }

    if (data is Map) {
      data.forEach((name, value) {
        builder.element(name, nest: () => _createNode(builder, value));
      });
      return;
    }

    builder.text(data.toString());
  }

  factory XmlConverter() {
    if (instance == null) {
      instance = new XmlConverter._create();
    }
    return instance;
  }

  // singleton instance
  static XmlConverter instance;
  XmlConverter._create();
}
