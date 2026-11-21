import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

final _site = Directory('site');
final _config = jsonDecode(File('content/site.json').readAsStringSync()) as Map;
final _base =
    Uri.parse('${_config['baseUrl']}'.replaceFirst(RegExp(r'/+$'), '') + '/');
final _attribute = RegExp(r'''([\w:-]+)\s*=\s*(?:"([^"]*)"|'([^']*)')''');
final _heading = RegExp(r'<h1\b', caseSensitive: false);
final _section = RegExp(r'<section\s+id="([^"]+)"');
final _jsonLd =
    RegExp(r'<script type="application/ld\+json">([\s\S]*?)</script>');

Map<String, String> _attrs(String tag) => {
      for (final match in _attribute.allMatches(tag))
        match[1]!: (match[2] ?? match[3]!).replaceAll('&amp;', '&'),
    };

Iterable<Map<String, String>> _tags(String html, String names) =>
    RegExp('<(?:$names)\\b[^>]*>', caseSensitive: false)
        .allMatches(html)
        .map((match) => _attrs(match[0]!));

bool _isLocal(Uri url) =>
    url.origin == _base.origin && url.path.startsWith(_base.path);

String _filePath(Uri url) {
  final path = Uri.decodeComponent(url.path.substring(_base.path.length));
  return '${_site.path}/$path${path.isEmpty || path.endsWith('/') ? 'index.html' : ''}';
}

String _route(File page) {
  final path = page.path.substring(_site.path.length + 1);
  return path.endsWith('index.html')
      ? path.substring(0, path.length - 'index.html'.length)
      : path;
}

void main() {
  final html = <String, String>{};
  setUpAll(() {
    final pages = _site
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.html'));
    for (final page in pages) {
      html[_route(page)] = page.readAsStringSync();
    }
  });

  test('all six pages have titles, descriptions, one H1 and social metadata',
      () {
    expect(
        html.keys,
        unorderedEquals(
            ['', 'ru/', 'en/', 'ru/guide/', 'en/guide/', '404.html']));
    for (final MapEntry(key: path, value: page) in html.entries) {
      expect(RegExp(r'<html lang="(?:ru|en)">').hasMatch(page), isTrue,
          reason: path);
      expect(RegExp(r'<title>[^<\s][^<]*</title>').hasMatch(page), isTrue,
          reason: path);
      expect(_heading.allMatches(page), hasLength(1), reason: path);
      final metadata = {
        for (final tag in _tags(page, 'meta'))
          if (tag['name'] != null || tag['property'] != null)
            (tag['name'] ?? tag['property'])!: tag['content'],
      };
      for (final key in [
        'description',
        'og:title',
        'og:description',
        'og:url',
        'og:image',
        'twitter:card'
      ]) {
        expect(metadata[key], isNotEmpty, reason: '$path $key');
      }
      final canonical = _tags(page, 'link')
          .singleWhere((tag) => tag['rel'] == 'canonical')['href'];
      expect(canonical, _base.resolve(path.isEmpty ? 'ru/' : path).toString(),
          reason: path);
      expect(metadata['og:url'], canonical, reason: path);
      expect(File(_filePath(Uri.parse(metadata['og:image']!))).existsSync(),
          isTrue,
          reason: path);
    }
  });

  test('links, fragments, imagery and alternate pages resolve locally', () {
    for (final MapEntry(key: path, value: page) in html.entries) {
      final pageUrl = _base.resolve(path);
      final alternates = {
        for (final tag
            in _tags(page, 'link').where((tag) => tag['rel'] == 'alternate'))
          tag['hreflang']: tag['href'],
      };
      expect(alternates.keys, unorderedEquals(['ru', 'en', 'x-default']),
          reason: path);
      final suffix = path.endsWith('guide/') ? 'guide/' : '';
      for (final language in ['ru', 'en']) {
        expect(
            alternates[language],
            _base
                .resolve(path == '404.html' ? path : '$language/$suffix')
                .toString(),
            reason: path);
      }
      expect(
          alternates['x-default'],
          _base
              .resolve(path == '404.html'
                  ? path
                  : (suffix.isEmpty ? '' : 'ru/guide/'))
              .toString(),
          reason: path);

      for (final tag in _tags(page, 'link|script|a|img')) {
        final target = tag['href'] ?? tag['src'];
        if (target == null) continue;
        final url = pageUrl.resolve(target);
        final reason = '$path → $target';
        if (tag['rel'] == 'alternate') {
          expect(_isLocal(url), isTrue, reason: reason);
        }
        if (!_isLocal(url)) continue;
        final file = File(_filePath(url));
        expect(file.existsSync(), isTrue, reason: reason);
        if (url.hasFragment && file.path.endsWith('.html')) {
          final ids = _tags(file.readAsStringSync(), '[a-z][a-z0-9]*')
              .map((tag) => tag['id']);
          expect(ids, contains(url.fragment), reason: reason);
        }
      }
      for (final tag in _tags(page, 'img')) {
        expect(
            tag['alt']?.isNotEmpty == true ||
                tag['src']!.endsWith('favicon.svg'),
            isTrue,
            reason: path);
        expect(int.tryParse(tag['width'] ?? ''), greaterThan(0), reason: path);
        expect(int.tryParse(tag['height'] ?? ''), greaterThan(0), reason: path);
        expect(tag['loading'], anyOf('eager', 'lazy'), reason: path);
      }
    }
  });

  test('scripts and resource links use no external hosts', () {
    const metadata = {'canonical', 'alternate'};
    for (final MapEntry(key: path, value: page) in html.entries) {
      final resources = [
        for (final tag in _tags(page, 'script|img'))
          if (tag['src'] != null) tag['src']!,
        for (final tag in _tags(page, 'link'))
          if (!metadata.contains(tag['rel'])) tag['href']!,
      ];
      for (final resource in resources) {
        final url = Uri.parse(resource);
        expect(url.hasScheme || url.hasAuthority, isFalse,
            reason: '$path → $resource');
      }
      final source = File('site/style.css').readAsStringSync();
      expect(
          source, isNot(matches(RegExp(r'''url\(\s*['"]?(?:https?:)?//'''))));
    }
  });

  test('JSON-LD parses and each landing has nine matching FAQ entries', () {
    for (final MapEntry(key: path, value: page) in html.entries) {
      final objects =
          _jsonLd.allMatches(page).map((match) => jsonDecode(match[1]!) as Map);
      if (!const {'ru/', 'en/'}.contains(path)) continue;
      final software =
          objects.singleWhere((data) => data['@type'] == 'SoftwareApplication');
      expect(software['operatingSystem'], 'Android 7.0+, Windows 10+, Linux');
      expect(software['softwareVersion'], _config['version']);
      expect(software['offers']['price'], 0);
      expect(software['author']['name'], _config['developer']);
      final faq = objects.singleWhere((data) => data['@type'] == 'FAQPage');
      expect(faq['mainEntity'], hasLength(15), reason: path);
      expect(_tags(page, 'details'), hasLength(15), reason: path);
      expect(_tags(page, 'img').where((tag) => tag['fetchpriority'] == 'high'),
          hasLength(1),
          reason: path);
    }
  });

  test(
      'sitemap covers all pages, has alternates and is advertised by robots.txt',
      () {
    final sitemap = File('site/sitemap.xml').readAsStringSync();
    final locations = RegExp(r'<loc>([^<]+)</loc>').allMatches(sitemap);
    expect(
        locations.map((match) => match[1]),
        unorderedEquals(
            html.keys.map((route) => _base.resolve(route).toString())));
    final entries = RegExp(r'<url>([\s\S]*?)</url>').allMatches(sitemap);
    expect(entries, hasLength(html.length));
    for (final entry in entries) {
      final tags = _tags(entry[1]!, 'xhtml:link');
      expect(tags.map((tag) => tag['hreflang']),
          unorderedEquals(['ru', 'en', 'x-default']));
      for (final tag in tags) {
        final url = Uri.parse(tag['href']!);
        expect(_isLocal(url), isTrue);
        expect(File(_filePath(url)).existsSync(), isTrue);
      }
    }
    final robots = File('site/robots.txt').readAsStringSync();
    expect(robots, contains('Allow: /'));
    expect(robots, contains('Sitemap: ${_base.resolve('sitemap.xml')}'));
  });

  test('Russian and English have matching section counts and order', () {
    for (final suffix in ['', 'guide/']) {
      final ru =
          _section.allMatches(html['ru/$suffix']!).map((match) => match[1]);
      final en =
          _section.allMatches(html['en/$suffix']!).map((match) => match[1]);
      expect(ru, hasLength(suffix.isEmpty ? 14 : 11));
      expect(ru, orderedEquals(en));
    }
  });

  test('the landing payload is under 1.5 MB including lazy screenshots', () {
    for (final language in ['ru', 'en']) {
      final pageUrl = _base.resolve('$language/');
      final page = html['$language/']!;
      final paths = {
        _filePath(pageUrl),
        'site/fonts/Manrope.ttf',
        for (final tag in _tags(page, 'link|script|img'))
          if (tag['href'] != null || tag['src'] != null)
            if (!const {'canonical', 'alternate'}.contains(tag['rel']))
              _filePath(pageUrl.resolve((tag['href'] ?? tag['src'])!)),
      };
      final bytes =
          paths.fold<int>(0, (sum, path) => sum + File(path).lengthSync());
      expect(bytes, lessThan(1500000), reason: '$language ($bytes bytes)');
    }
  });
}
