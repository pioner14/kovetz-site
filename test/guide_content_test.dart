import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

const _chapterIds = [
  'what',
  'install',
  'main_screen',
  'safety',
  'merge',
  'restore',
  'export',
  'settings',
  'problems',
  'privacy',
  'words',
];

const _imageMarkers = {
  'home': 4,
  'drawer': 5,
  'language_dialog': 3,
  'theme_dialog': 3,
  'merge_files_empty': 2,
  'merge_files_two': 3,
  'merge_rules': 3,
  'merge_progress': 2,
  'merge_done': 4,
  'export_overview': 4,
  'export_format': 4,
  'export_pdf_options': 2,
  'pdf_cover': 2,
  'pdf_page': 2,
  'updates': 2,
  'about': 2,
};

const _allowedLatin = [
  'JW Library',
  'Kovetz',
  'Obsidian',
  'Markdown',
  'PDF',
  'GitHub',
  'ZIP',
  'APK',
  'Linux',
  'Windows',
  'Android',
  'TXT',
  'JSON',
  'Flutter',
  'Syncthing',
];

void main() {
  final source = Directory('content');
  final guides = <String, Map<String, dynamic>>{};

  setUpAll(() {
    for (final language in ['ru', 'en']) {
      final file = File('${source.path}/guide.$language.json');
      guides[language] =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  });

  test('both guides have valid chapters, blocks, steps and images', () {
    for (final MapEntry(key: language, value: guide) in guides.entries) {
      _keys(guide, {'title', 'intro', 'chapters'});
      _text(guide['title'], '$language title');
      _text(guide['intro'], '$language intro');
      final chapters = _entries(guide, 'chapters');
      expect(chapters.map((chapter) => chapter['id']), _chapterIds);
      final usedImages = <String>{};

      for (final chapter in chapters) {
        final label = '$language/${chapter['id']}';
        _keys(chapter, {'id', 'title', 'summary', 'blocks'});
        _text(chapter['title'], '$label title');
        _text(chapter['summary'], '$label summary');
        final blocks = _entries(chapter, 'blocks');
        expect(blocks, isNotEmpty, reason: label);
        var nextStep = 1;

        for (final block in blocks) {
          switch (block['type']) {
            case 'step':
              _keys(
                block,
                {'type', 'number', 'title', 'text'},
                optional: {'image', 'note'},
              );
              expect(block['number'], isA<int>(), reason: label);
              expect(block['number'], nextStep++, reason: label);
              _text(block['title'], '$label step title');
              _text(block['text'], '$label step text');
              if (block.containsKey('note')) {
                _text(block['note'], '$label step note');
              }
              if (block.containsKey('image')) {
                final image = _text(block['image'], '$label image id');
                final count = _imageMarkers[image];
                expect(count, isNotNull, reason: '$label/$image');
                usedImages.add(image);
                expect(
                  File('assets/guide/$language/$image.png').existsSync(),
                  isTrue,
                  reason: '$label/$image image file',
                );
                final note = _text(block['note'], '$label/$image marker note');
                final markers = RegExp(r'(?:^|\s)(\d+) — ')
                    .allMatches(note)
                    .map((match) => int.parse(match.group(1)!));
                expect(
                  markers,
                  List.generate(count!, (index) => index + 1),
                  reason: '$label/$image markers',
                );
              }
            case 'list':
              _keys(block, {'type', 'items'});
              final items = block['items'];
              expect(items, isA<List<dynamic>>(), reason: label);
              expect(items, isNotEmpty, reason: label);
              for (final item in items as List<dynamic>) {
                _text(item, '$label list item');
              }
            case 'p':
            case 'tip':
            case 'warning':
              _keys(block, {'type', 'text'});
              _text(block['text'], '$label ${block['type']}');
            default:
              fail('$label unknown block type: ${block['type']}');
          }
        }
      }
      expect(usedImages, unorderedEquals(_imageMarkers.keys), reason: language);
    }
  });

  test('both languages have the same chapter and step structure', () {
    List<Object?> structure(Map<String, dynamic> guide) => [
          for (final chapter in _entries(guide, 'chapters'))
            [
              chapter['id'],
              for (final block in _entries(chapter, 'blocks'))
                [block['type'], block['number'], block['image']],
            ],
        ];
    expect(structure(guides['ru']!), structure(guides['en']!));
  });

  test('Russian prose uses only the allowed Latin names', () {
    final allowed = RegExp(
      r'(?<![A-Za-z])(?:' +
          _allowedLatin.map(RegExp.escape).join('|') +
          r')(?![A-Za-z])',
    );
    final latin = RegExp(r'\p{Script=Latin}', unicode: true);
    for (final string in _prose(guides['ru'])) {
      expect(
        latin.hasMatch(string.replaceAll(allowed, '')),
        isFalse,
        reason: string,
      );
    }
  });

  test('both troubleshooting chapters cover the merge error topics', () {
    for (final guide in guides.values) {
      final problems = _entries(
        guide,
        'chapters',
      ).singleWhere((chapter) => chapter['id'] == 'problems');
      expect(_entries(problems, 'blocks').length, greaterThanOrEqualTo(12));
    }
  });
}

void _keys(
  Map<String, dynamic> object,
  Set<String> required, {
  Set<String> optional = const {},
}) {
  expect(object.keys, containsAll(required));
  expect(object.keys.toSet().difference({...required, ...optional}), isEmpty);
}

String _text(Object? value, String label) {
  expect(value, isA<String>(), reason: label);
  final string = value as String;
  expect(string.trim(), isNotEmpty, reason: label);
  return string;
}

List<Map<String, dynamic>> _entries(Map<String, dynamic> parent, String key) {
  final value = parent[key];
  expect(value, isA<List<dynamic>>(), reason: key);
  final entries = value as List<dynamic>;
  expect(entries, everyElement(isA<Map<String, dynamic>>()), reason: key);
  return entries.cast<Map<String, dynamic>>();
}

Iterable<String> _prose(Object? value) sync* {
  if (value is String) {
    yield value;
  } else if (value is List<dynamic>) {
    for (final item in value) {
      yield* _prose(item);
    }
  } else if (value is Map<String, dynamic>) {
    for (final entry in value.entries) {
      if (!const {'id', 'type', 'image'}.contains(entry.key)) {
        yield* _prose(entry.value);
      }
    }
  }
}
