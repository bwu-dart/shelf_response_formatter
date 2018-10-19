library shelf_response_formatter.xml_converter;

import 'package:xml/xml.dart';

/// Creates an XML String from a given simple data structure consisting of
/// [String], [num], [bool], [Map] and [List].
/// [Map] and [List] are iterated recursively all other types are added as text
/// nodes calling toString.
class XmlConverter {
  /// Convert method takes data a returns it as XML [String]
  String convert([Object data]) => toXml(data).toXmlString(pretty: true);

  /// Converts given data into an [XmlElement].
  XmlElement toXml([Object data]) {
    final builder = XmlBuilder();
//    builder.processing('xml', 'version="1.0"');
    builder.element('response', nest: () => _createNode(builder, data));
    return builder.build().firstChild as XmlElement;
  }

  // internal recursive converter
  void _createNode(XmlBuilder builder, Object data) {
    if (data == null) {
      return;
    }

    if (data is Iterable) {
      data
          // ignore: avoid_types_on_closure_parameters
          .map((Object item) =>
              builder.element('item', nest: () => _createNode(builder, item)))
          .toList(growable: false);
      return;
    }

    if (data is Map) {
      // ignore: avoid_types_on_closure_parameters
      data.forEach((Object name, Object value) {
        builder.element(name as String,
            nest: () => _createNode(builder, value));
      });
      return;
    }

    builder.text(data.toString());
  }

  factory XmlConverter() => instance ??= XmlConverter._create();

  // singleton instance
  static XmlConverter instance;
  XmlConverter._create();
}
