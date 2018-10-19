@TestOn('vm')
library shelf_response_formatter.test.formatter;

import 'dart:convert';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_response_formatter/shelf_response_formatter.dart';

void main() {
  const baseUrl = 'http://www.test.io';
  shelf.Request createShelfRequest(String method, String path,
      [Map<String, String> headers]) {
    final uri = Uri.parse(baseUrl + path);
    headers ??= {'accept': '*/*'};
    return shelf.Request(method, uri, headers: headers);
  }

  final formatter = ResponseFormatter();

  final defaultRequest = createShelfRequest(
      'GET', '/asdf/qwer', {'Accept': 'audio/*; q=0.2, audio/basic'});
  final strangeRequest = createShelfRequest('GET', '/asdf/qwer');
  final queryFormatXml = createShelfRequest('GET', '/asdf/qwer?format=xml');
  final queryFormatJson = createShelfRequest('GET', '/asdf/qwer?format=json');
  final fileFormatXml = createShelfRequest('GET', '/asdf/qwer.xml');
  final fileFormatJson = createShelfRequest('GET', '/asdf/qwer.json');
  final chromeGetRequest = createShelfRequest('GET', '/asdf/qwer&format=xml', {
    'accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
  });
  final csvGetRequest = createShelfRequest(
      'GET', '/asdf/qwer&format=csv', {'accept': 'text/csv'});
  final csvOverrideRequest = createShelfRequest(
      'GET', '/asdf/qwer', {'accept': 'application/xhtml+xml'});

  group('formatResponse', () {
    test('is function', () {
      expect(formatter.formatResponse is Function, isTrue);
    });

    test('returns empty text message for nothing found', () {
      final res = formatter.formatResponse(defaultRequest, <String, dynamic>{});
      expect(res.body, equals(''));
      expect(res.contentType, equals('text/plain'));
    });

    test('returns FormatResult', () {
      final res = formatter.formatResponse(defaultRequest, <String, dynamic>{});
      expect(res is FormatResult, isTrue);
    });

    test('returns text message from response data', () {
      final res =
          formatter.formatResponse(defaultRequest, {'message': 'hello'});
      expect(res.body, equals('hello'));
      expect(res.contentType, equals('text/plain'));
    });

    test('returns json response from map data', () {
      final data = {
        'a': 'b',
        'c': ['a', 'b', 'c']
      };
      final queryJsonRes = formatter.formatResponse(queryFormatJson, data);
      final fileJsonRes = formatter.formatResponse(fileFormatJson, data);
      final queryJsonString = queryJsonRes.body;
      final fileJsonString = fileJsonRes.body;
      expect(queryJsonString, equals(fileJsonString));
      expect(data, equals(json.decode(queryJsonString)));
      expect(queryJsonRes.contentType, equals('application/json'));
      expect(fileJsonRes.contentType, equals('application/json'));
    });

    test('returns json response from array', () {
      final data = [
        {'a': 1},
        {'a': 2},
        {'a': 3}
      ];
      final queryJsonRes = formatter.formatResponse(queryFormatJson, data);
      final fileJsonRes = formatter.formatResponse(fileFormatJson, data);
      final queryJsonString = queryJsonRes.body;
      final fileJsonString = fileJsonRes.body;
      expect(queryJsonString, equals(fileJsonString));
      expect(data, equals(json.decode(queryJsonString)));
      expect(queryJsonRes.contentType, equals('application/json'));
      expect(fileJsonRes.contentType, equals('application/json'));
    });

    test('returns empty text response from strange request', () {
      expect(formatter.formatResponse(strangeRequest, null).body, equals(''));
    });

    test('returns xml response from strange request', () {
      expect(
          formatter
              .formatResponse(fileFormatXml, {'a': 0})
              .body
              .replaceAll('\n', '')
              .replaceAll(' ', ''),
          equals('<response><a>0</a></response>'));
    });

    test('calls to string on non covertible objects in XML', () {
      final date = DateTime.now();
      final data = date;
      final queryJsonRes = formatter.formatResponse(queryFormatXml, data);
      expect(queryJsonRes.body.replaceAll('\r', ''),
          equals('<response>${date.toString()}</response>'));
    });

    test('calls to string on non covertible objects in Json', () {
      final date = DateTime.now();
      final data = {'date': date};
      final queryJsonRes = formatter.formatResponse(queryFormatJson, data);
      expect(queryJsonRes.body, equals('{"date":"${date.toString()}"}'));
    });
  });

  group('findTargetFormat', () {
    test('is function', () {
      expect(formatter.findTargetFormat is Function, isTrue);
    });

    test('takes request and returns string', () {
      expect(formatter.findTargetFormat(defaultRequest) is String, isTrue);
    });

    test('returns xml from browser format query param', () {
      expect(formatter.findTargetFormat(queryFormatXml), equals('xml'));
    });

    test('returns json from browser format query param', () {
      expect(formatter.findTargetFormat(queryFormatJson), equals('json'));
    });

    test('returns text from no formatter for browser format query param', () {
      expect(formatter.findTargetFormat(defaultRequest), equals('text'));
    });

    test('returns json from url file extension .json', () {
      expect(formatter.findTargetFormat(fileFormatJson), equals('json'));
    });

    test('returns xml from url file extension .xml', () {
      expect(formatter.findTargetFormat(fileFormatXml), equals('xml'));
    });

    test('returns xml from browser accept header', () {
      expect(formatter.findTargetFormat(chromeGetRequest), equals('xml'));
    });

    test('returns text from strange audio request', () {
      expect(formatter.findTargetFormat(strangeRequest), equals('text'));
    });
  });

  group('register formatter', () {
    // ignore: avoid_types_on_closure_parameters
    formatter.registerFormatter('csv', 'text/csv', (Object data) => 'CSV',
        ['application/json', 'application/xhtml+xml']);

    test('CSV is target format', () {
      expect(formatter.findTargetFormat(csvGetRequest), equals('csv'));
    });

    test('CSV is result', () {
      final res = formatter.formatResponse(csvGetRequest, null);
      expect(res.contentType, equals('text/csv'));
      expect(res.body, equals('CSV'));
    });

    test('CSV is result for overridden accept header', () {
      final res = formatter.formatResponse(csvOverrideRequest, null);
      expect(res.contentType, equals('text/csv'));
      expect(res.body, equals('CSV'));
    });
  });
}
