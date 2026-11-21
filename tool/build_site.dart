import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'guide_data.dart';

const _escape = HtmlEscape(HtmlEscapeMode(escapeLtGt: true, escapeQuot: true));
String h(String text) => _escape.convert(text);
const _platforms = ['Android', 'Windows', 'Linux'];
const _stepImages = ['merge_files_two', 'merge_rules', 'export_format'];

void main() {
  final root = Directory.fromUri(Platform.script.resolve('../'));
  Directory.current = root;
  final config = readData('content/site.json').cast<String, String>();
  final staging = Directory('.').createTempSync('.site-build-');
  final output = Directory('${staging.path}/output')..createSync();
  final previous = Directory('${staging.path}/previous');
  final site = Directory('site');

  try {
    SiteBuilder(output, config).build();
    if (site.existsSync()) site.renameSync(previous.path);
    try {
      output.renameSync(site.path);
    } catch (_) {
      if (previous.existsSync()) previous.renameSync(site.path);
      rethrow;
    }
  } finally {
    staging.deleteSync(recursive: true);
  }
}

class SiteBuilder {
  SiteBuilder(this.output, this.config);

  final Directory output;
  final Map<String, String> config;
  final _pages = <String, Map<String, String>>{};

  String get base => config['baseUrl']!.replaceFirst(RegExp(r'/+$'), '');
  String get name => config['name']!;
  String get developer => config['developer']!;
  String get releases => config['releases']!;
  String get archive => releases.replaceFirst(RegExp(r'/latest/?$'), '');

  File target(String path) => File('${output.path}/$path');
  void write(String path, String text) =>
      (target(path)..createSync(recursive: true)).writeAsStringSync(text);

  void copy(String source, String path) {
    final file = target(path);
    file.parent.createSync(recursive: true);
    File(source).copySync(file.path);
  }

  void build() {
    for (final file in ['style.css', 'site.js']) {
      copy('src/$file', file);
    }
    for (final file in ['Manrope.ttf', 'OFL-Manrope.txt']) {
      copy('assets/fonts/$file', 'fonts/$file');
    }
    copy('LICENSE', 'LICENSE.txt');
    copy('assets/brand/app_icon.svg', 'favicon.svg');
    _branding();

    for (final language in guideLanguages.keys) {
      final locale = LocalePages(
        this,
        language,
        readData('content/landing.$language.json'),
      );
      locale.landing();
      locale.guide(readGuide(Directory('content'), language));
    }
    _otherPages();
    _indexFiles();
  }

  void _branding() {
    for (final entry
        in {'apple-touch-icon.png': 180, 'icon-512.png': 512}.entries) {
      magick([
        '-background',
        'none',
        'assets/brand/app_icon.svg',
        '-resize',
        '${entry.value}x${entry.value}',
        '-depth',
        '8',
        '-strip',
        target(entry.key).path,
      ]);
    }
    final seo = readData('content/landing.ru.json')['seo'] as GuideData;
    magick([
      '-size',
      '1200x630',
      'xc:#376754',
      '(',
      target('icon-512.png').path,
      '-resize',
      '220x220',
      ')',
      '-gravity',
      'West',
      '-geometry',
      '+82+0',
      '-composite',
      '-gravity',
      'NorthWest',
      '-font',
      'assets/fonts/Manrope.ttf',
      '-fill',
      '#F7F7F3',
      '-pointsize',
      '100',
      '-annotate',
      '+350+231',
      name,
      '-fill',
      '#E1F6EA',
      '-pointsize',
      '32',
      '-annotate',
      '+354+363',
      seo['tagline'] as String,
      '-depth',
      '8',
      '-strip',
      target('og.png').path,
    ]);
  }

  void magick(List<String> arguments) {
    final result = Process.runSync('magick', arguments);
    if (result.exitCode != 0) throw StateError('ImageMagick: ${result.stderr}');
  }

  Map<String, String> alternatives(String suffix) => {
        for (final language in guideLanguages.keys)
          language: '$base/$language/$suffix',
        'x-default': suffix.isEmpty ? '$base/' : '$base/ru/$suffix',
      };

  void page({
    required String file,
    required String locale,
    required String title,
    required String description,
    required String url,
    required Map<String, String> alternates,
    required String prefix,
    required String body,
    String? canonical,
    String extraHead = '',
    String bodyAttributes = '',
    List<Map<String, Object>> structured = const [],
  }) {
    _pages[url] = alternates;
    write(file, '''
<!doctype html>
<html lang="$locale">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${h(title)}</title>
  <meta name="description" content="${h(description)}">
  <link rel="canonical" href="${h(canonical ?? url)}">
${alternateTags(alternates, 'link')}
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="${h(name)}">
  <meta property="og:locale" content="${locale == 'ru' ? 'ru_RU' : 'en_US'}">
  <meta property="og:title" content="${h(title)}">
  <meta property="og:description" content="${h(description)}">
  <meta property="og:url" content="${h(canonical ?? url)}">
  <meta property="og:image" content="${h('$base/og.png')}">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta property="og:image:alt" content="${h(name)}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="${h(title)}">
  <meta name="twitter:description" content="${h(description)}">
  <meta name="twitter:image" content="${h('$base/og.png')}">
  <link rel="icon" href="${prefix}favicon.svg" type="image/svg+xml">
  <link rel="apple-touch-icon" href="${prefix}apple-touch-icon.png">
  <link rel="manifest" href="${prefix}site.webmanifest">
  <link rel="stylesheet" href="${prefix}style.css">
  <script src="${prefix}site.js" defer></script>
$extraHead
${structured.map((value) => '  <script type="application/ld+json">${jsonEncode(value).replaceAll('<', r'\u003c')}</script>').join('\n')}
</head>
<body$bodyAttributes>
$body
</body>
</html>
''');
  }

  String alternateTags(Map<String, String> links, String tag) => links.entries
      .map((entry) =>
          '    <$tag rel="alternate" hreflang="${entry.key}" href="${h(entry.value)}"${tag == 'link' ? '>' : ' />'}')
      .join('\n');

  void _otherPages() {
    page(
      file: 'index.html',
      locale: 'ru',
      title: '$name — Русский · English',
      description:
          'Выберите язык сайта Kovetz. Choose a language for the Kovetz website.',
      url: '$base/',
      canonical: '$base/ru/',
      alternates: alternatives(''),
      prefix: '',
      extraHead:
          '  <noscript><meta http-equiv="refresh" content="0; url=ru/"></noscript>',
      bodyAttributes: ' data-language-redirect',
      body: '''
<main class="container standalone" id="main">
  <h1>${h(name)}</h1>
  <p>Выберите язык. <span lang="en">Choose a language.</span></p>
  <div class="actions">
    <a class="button primary" href="ru/index.html" hreflang="ru">Русский</a>
    <a class="button" href="en/index.html" hreflang="en" lang="en">English</a>
  </div>
</main>''',
    );

    final error = '$base/404.html';
    // A Pages error page can be served at any unknown depth.
    final prefix = '${Uri.parse(base).path}/';
    page(
      file: '404.html',
      locale: 'ru',
      title: '$name — Страница не найдена · Page not found',
      description:
          'Страница не найдена. The requested page could not be found.',
      url: error,
      alternates: {
        for (final code in ['ru', 'en', 'x-default']) code: error
      },
      prefix: prefix,
      body: '''
<main class="container standalone" id="main">
  <h1>Страница не найдена</h1>
  <p lang="en">Page not found.</p>
  <div class="actions">
    <a class="button primary" href="${prefix}ru/" hreflang="ru">Главная на русском</a>
    <a class="button" href="${prefix}en/" lang="en" hreflang="en">English home page</a>
  </div>
</main>''',
    );
  }

  void _indexFiles() {
    write('sitemap.xml', '''
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">
${_pages.entries.map((page) => '  <url>\n    <loc>${h(page.key)}</loc>\n${alternateTags(page.value, 'xhtml:link')}\n  </url>').join('\n')}
</urlset>
''');
    write(
        'robots.txt', 'User-agent: *\nAllow: /\nSitemap: $base/sitemap.xml\n');
    write(
        'site.webmanifest',
        '${const JsonEncoder.withIndent('  ').convert({
              'name': name,
              'short_name': name,
              'start_url': './',
              'scope': './',
              'display': 'standalone',
              'theme_color': '#376754',
              'background_color': '#F7F7F3',
              'icons': [
                {
                  'src': 'icon-512.png',
                  'sizes': '512x512',
                  'type': 'image/png'
                },
                {'src': 'favicon.svg', 'sizes': 'any', 'type': 'image/svg+xml'},
              ],
            })}\n');
  }
}

class LocalePages {
  LocalePages(this.site, this.language, this.copy);

  final SiteBuilder site;
  final String language;
  final GuideData copy;

  String t(String section, String key) => h(copy[section][key] as String);
  String ui(String key) => t('ui', key);
  String text(GuideData entry, String key) => h(entry[key] as String);

  String header({bool guide = false}) {
    final prefix = guide ? '../../' : '../';
    final home = guide ? '../index.html' : 'index.html';
    final suffix = guide ? 'guide/' : '';
    final nav = {
      'features': '$home#features',
      'steps': '$home#steps',
      'guide': guide ? 'index.html' : 'guide/index.html',
      'download': '$home#download',
      'faq': '$home#faq',
      'support': '$home#support',
    };
    final themeOptions = (copy['ui']['themes'] as List<dynamic>).cast<String>();
    return '''
<a class="skip-link" href="#main">${ui('skip')}</a>
<header class="site-header">
  <div class="container header-inner">
    <a class="brand" href="$home"><img src="${prefix}favicon.svg" alt="${h(site.name)}" width="40" height="40" loading="eager"><span aria-hidden="true">${h(site.name)}</span></a>
    <nav class="main-nav" aria-label="${ui('navigation')}">
      ${nav.entries.map((entry) => '<a href="${entry.value}"${guide && entry.key == 'guide' ? ' aria-current="page"' : ''}>${ui(entry.key)}</a>').join('\n      ')}
    </nav>
    <div class="header-controls">
      <nav class="language-switch" aria-label="${ui('languages')}">
        ${guideLanguages.keys.map((code) => '<a href="$prefix$code/${suffix}index.html" lang="$code" hreflang="$code" aria-label="${guideLanguages[code]}"${code == language ? ' aria-current="page"' : ''}>${code.toUpperCase()}</a>').join('\n        ')}
      </nav>
      <label class="theme-control" title="${ui('theme')}" hidden>
        ${icon('theme')}
        <select data-theme-select aria-label="${ui('theme')}">
          ${[
      'auto',
      'light',
      'dark'
    ].indexed.map((item) => '<option value="${item.$2}">${h(themeOptions[item.$1])}</option>').join('\n          ')}
        </select>
      </label>
      <button class="theme-toggle" type="button" data-theme-toggle aria-label="${h(themeOptions[2])}" aria-pressed="false" title="${ui('theme')}" hidden>
        ${icon('theme')}
      </button>
    </div>
  </div>
</header>''';
  }

  String footer(String prefix) => '''
<footer class="site-footer">
  <div class="container">
    <div class="footer-links">
      <span>© 2026 ${h(site.developer)}</span>
      <a href="${prefix}LICENSE.txt">${ui('license')}</a>
      <a href="${h(site.config['repo']!)}">${ui('source')}</a>
    </div>
    <p>${ui('disclaimer')}</p>
  </div>
</footer>''';

  String screenshot(String file, String alt, {bool eager = false}) {
    final path = 'screens/$language/$file.png';
    if (!File('assets/$path').existsSync()) {
      stderr.writeln('Skipping missing mock-up: assets/$path');
      return '';
    }
    return image(path, '../', alt, eager: eager);
  }

  String image(String path, String prefix, String alt, {bool eager = false}) {
    final source = 'assets/$path';
    final png = File(source).openSync();
    late final ByteData bytes;
    try {
      bytes = ByteData.sublistView(png.readSync(24));
    } finally {
      png.closeSync();
    }
    final width = bytes.getUint32(16);
    final height = bytes.getUint32(20);
    site.copy(source, path);
    return '<img src="$prefix${h(path)}" alt="$alt" width="$width" height="$height" '
        'loading="${eager ? 'eager" fetchpriority="high' : 'lazy'}">';
  }

  String phone(String file, String alt,
      {bool eager = false, bool rear = false}) {
    final shot = screenshot(file, alt, eager: eager);
    return shot.isEmpty
        ? ''
        : '<div class="phone${rear ? ' phone-rear' : ''}">$shot</div>';
  }

  void landing() {
    final faq = guideEntries(copy['faq'] as GuideData, 'items');
    final heroPhone = phone('merge_done', t('hero', 'alt'), eager: true);
    final rearPhone = phone('home', t('hero', 'homeAlt'), rear: true);
    site.page(
      file: '$language/index.html',
      locale: language,
      title: copy['seo']['title'] as String,
      description: copy['seo']['description'] as String,
      url: '${site.base}/$language/',
      alternates: site.alternatives(''),
      prefix: '../',
      structured: [
        {
          '@context': 'https://schema.org',
          '@type': 'SoftwareApplication',
          'name': site.name,
          'description': copy['seo']['description'] as String,
          'operatingSystem': _platforms.join(', '),
          'applicationCategory': 'UtilitiesApplication',
          'softwareVersion': site.config['version']!,
          'downloadUrl': site.releases,
          'offers': {'@type': 'Offer', 'price': 0, 'priceCurrency': 'EUR'},
          'author': {'@type': 'Person', 'name': site.developer},
        },
        {
          '@context': 'https://schema.org',
          '@type': 'FAQPage',
          'mainEntity': [
            for (final item in faq)
              {
                '@type': 'Question',
                'name': item['question'],
                'acceptedAnswer': {'@type': 'Answer', 'text': item['answer']}
              },
          ],
        },
      ],
      body: '''
${header()}
<main id="main" tabindex="-1">
  <section id="hero" class="section hero">
    <div class="container split hero-inner">
      <div class="hero-copy">
        <h1>${t('hero', 'title')}</h1>
        <p class="lede">${t('hero', 'text')}</p>
        <div class="actions">
          <a class="button primary" href="#download">${icon('download')}${t('hero', 'download')}</a>
          <a class="button" href="#steps">${ui('steps')}</a>
        </div>
        <ul class="chips" role="list">
          ${(copy['hero']['chips'] as List<dynamic>).map((chip) => '<li>${h(chip as String)}</li>').join('\n          ')}
        </ul>
      </div>
      ${heroPhone.isEmpty ? '' : '<div class="hero-phones">$rearPhone$heroPhone</div>'}
    </div>
  </section>
  <section id="problem" class="section band">
    <div class="container split">
      <div><h2>${t('problem', 'title')}</h2><p>${t('problem', 'text')}</p></div>
      ${diagram()}
    </div>
  </section>
  <section id="solution" class="section">
    <div class="container split">
      <div><h2>${t('solution', 'title')}</h2><p>${t('solution', 'text')}</p></div>
      <ul class="checklist" role="list">
        ${(copy['solution']['points'] as List<dynamic>).map((point) => '<li>${icon('check')}${h(point as String)}</li>').join('\n        ')}
      </ul>
    </div>
  </section>
  <section id="features" class="section band">
    <div class="container">
      <h2>${t('features', 'title')}</h2>
      <div class="grid-three">
        ${guideEntries(copy['features'] as GuideData, 'cards').indexed.map((item) => '''
        <article class="card">
          <span class="icon-tile">${icon([
                'stack',
                'book',
                'folder'
              ][item.$1])}</span>
          <h3>${text(item.$2, 'title')}</h3><p>${text(item.$2, 'text')}</p>
        </article>''').join('\n')}
      </div>
    </div>
  </section>
  <section id="steps" class="section">
    <div class="container">
      <h2>${t('steps', 'title')}</h2>
      <ol class="grid-three workflow" role="list">
        ${guideEntries(copy['steps'] as GuideData, 'cards').indexed.map((item) => '''
        <li class="card workflow-step">
          <div class="workflow-copy">
            <span class="step-number" aria-hidden="true">${item.$1 + 1}</span>
            <h3>${text(item.$2, 'title')}</h3><p>${text(item.$2, 'text')}</p>
          </div>
          ${phone(_stepImages[item.$1], text(item.$2, 'alt'))}
        </li>''').join('\n')}
      </ol>
      <a class="guide-link" href="guide/index.html">${t('steps', 'guide')}</a>
    </div>
  </section>
  <section id="export" class="section band">
    <div class="container">
      <h2>${t('export', 'title')}</h2>
      ${exportCards()}
    </div>
  </section>
  <section id="privacy" class="section">
    <div class="container feature-callout">
      <span class="icon-tile">${icon('lock')}</span>
      <div><h2>${t('privacy', 'title')}</h2><p>${t('privacy', 'text')}</p></div>
    </div>
  </section>
  <section id="guide" class="section band">
    <div class="container feature-callout">
      <span class="icon-tile">${icon('book')}</span>
      <div>
        <h2>${t('guide', 'title')}</h2><p>${t('guide', 'text')}</p>
        <a class="button" href="guide/index.html">${t('guide', 'action')}</a>
      </div>
    </div>
  </section>
  <section id="download" class="section">
    <div class="container">
      <h2>${t('download', 'title')}</h2>
      <p class="version">${t('download', 'version')} <strong>${h(site.config['version']!)}</strong></p>
      <div class="grid-three platforms">
        ${_platforms.indexed.map((item) => '''
        <a class="card platform" href="${h(site.releases)}">
          ${icon(item.$2.toLowerCase())}
          <span><strong>${item.$2}</strong><small>${h(copy['download']['formats'][item.$1] as String)}</small></span>
          ${icon('download')}
        </a>''').join('\n')}
      </div>
      <div class="download-links">
        <a href="${h(site.archive)}">${t('download', 'all')}</a>
        <a href="guide/index.html#install">${t('download', 'note')}</a>
      </div>
    </div>
  </section>
  <section id="support" class="section band">
    <div class="container feature-callout">
      <span class="icon-tile">${icon('heart')}</span>
      <div>
        <h2>${t('support', 'title')}</h2><p>${t('support', 'text')}</p>
        <div class="actions">
          <a class="button primary" href="${h(site.config['paypal5']!)}">${t('support', 'coffee')}</a>
          <a class="button" href="${h(site.config['paypal']!)}">${t('support', 'custom')}</a>
        </div>
      </div>
    </div>
  </section>
  <section id="faq" class="section">
    <div class="container faq">
      <h2>${t('faq', 'title')}</h2>
      ${faq.map((item) => '<details name="faq"><summary>${text(item, 'question')}</summary><p>${text(item, 'answer')}</p></details>').join('\n      ')}
    </div>
  </section>
</main>
${footer('../')}''',
    );
  }

  String diagram() {
    final devices =
        (copy['problem']['devices'] as List<dynamic>).cast<String>();
    return '''
<figure class="diagram">
  <svg viewBox="0 0 480 249" role="img" aria-label="${t('problem', 'diagramAlt')}">
    <g class="diagram-lines">
      <path d="M80 91V111Q80 135 106 135H240 M240 91V162 M400 91V111Q400 135 374 135H240 M233 153L240 162L247 153"/>
    </g>
    <g class="diagram-tiles">
      <rect x="55" y="4" width="50" height="50" rx="13"/>
      <rect x="215" y="4" width="50" height="50" rx="13"/>
      <rect x="375" y="4" width="50" height="50" rx="13"/>
      <rect x="214" y="174" width="52" height="39" rx="11"/>
    </g>
    <g class="diagram-symbols">
      <rect x="73" y="16" width="14" height="25" rx="3"/><path d="M79 36h2"/>
      <rect x="230" y="16" width="20" height="25" rx="3"/><path d="M239 36h2"/>
      <rect x="387" y="17" width="26" height="16" rx="2"/><path d="M400 33v7m-8 0h16"/>
      <path d="m227 190 13-6 13 6-13 6-13-6Zm0 6 13 6 13-6m-26 6 13 6 13-6"/>
    </g>
    <g class="diagram-labels">
      ${devices.indexed.map((item) => '<text x="${80 + item.$1 * 160}" y="80">${h(item.$2)}</text>').join()}
      <text x="240" y="242">${t('problem', 'result')}</text>
    </g>
  </svg>
</figure>''';
  }

  String exportCards() {
    final pdf = copy['export']['pdf'] as GuideData;
    final obsidian = copy['export']['obsidian'] as GuideData;
    final tree =
        (obsidian['tree'] as List<dynamic>).cast<String>().map(h).toList();
    final cover = screenshot('pdf_cover', text(pdf, 'coverAlt'));
    final page = screenshot('pdf_page', text(pdf, 'pageAlt'));
    return '''
<div class="grid-two export-grid">
  <article class="card export-card">
    <h3>${text(pdf, 'title')}</h3><p>${text(pdf, 'text')}</p>
    ${cover.isEmpty && page.isEmpty ? '' : '<div class="pdf-preview">$cover$page</div>'}
  </article>
  <article class="card export-card">
    <h3>${text(obsidian, 'title')}</h3><p>${text(obsidian, 'text')}</p>
    <div class="tree">
      <div>${icon('folder')}${tree[0]}</div>
      <ul>
        <li>${tree[1]}</li>
        <li>${tree[2]}<ul><li>${tree[3]}</li></ul></li>
        <li>${tree[4]}<ul><li>${tree[5]}</li></ul></li>
      </ul>
    </div>
  </article>
</div>''';
  }

  void guide(GuideData guide) {
    final chapters = guideEntries(guide, 'chapters');
    final title = guide['title'] as String;
    final intro = guide['intro'] as String;
    site.page(
      file: '$language/guide/index.html',
      locale: language,
      title: '$title · ${site.name}',
      description: intro,
      url: '${site.base}/$language/guide/',
      alternates: site.alternatives('guide/'),
      prefix: '../../',
      body: '''
${header(guide: true)}
<main class="container guide-layout" id="main" tabindex="-1">
  <div class="guide-intro">
    <h1>${h(title)}</h1>
    <p class="lede">${h(intro)}</p>
  </div>
  <nav class="contents card" aria-labelledby="contents-title">
    <h2 id="contents-title">${ui('contents')}</h2>
    <ol>
      ${chapters.map((chapter) => '<li><a href="#${text(chapter, 'id')}">${text(chapter, 'title')}</a></li>').join('\n      ')}
    </ol>
  </nav>
  <div class="guide-chapters">
    ${chapters.map(guideChapter).join('\n    ')}
    <p class="back-top"><a href="#main">${ui('top')}</a></p>
  </div>
</main>
${footer('../../')}''',
    );
  }

  String guideChapter(GuideData chapter) {
    final id = text(chapter, 'id');
    return '''
<section id="$id" aria-labelledby="$id-title">
  <h2 id="$id-title">${text(chapter, 'title')}</h2>
  <p class="chapter-summary">${text(chapter, 'summary')}</p>
  ${guideEntries(chapter, 'blocks').map((block) => guideBlock(block, linkReleases: id == 'install')).join('\n  ')}
</section>''';
  }

  String guideBlock(GuideData block, {required bool linkReleases}) {
    final type = block['type'];
    switch (type) {
      case 'list':
        final items = (block['items'] as List<dynamic>).cast<String>();
        return '<ul>${items.map((item) => '<li>${h(item)}</li>').join()}</ul>';
      case 'step':
        final title = text(block, 'title');
        final prose = text(block, 'text');
        final body = linkReleases
            ? prose.replaceFirst(
                'GitHub', '<a href="${h(site.archive)}">GitHub</a>')
            : prose;
        final picture = block['image'] as String?;
        final note = block['note'] as String?;
        final caption = note == null ? '' : h(note);
        final illustration = picture == null
            ? (note == null ? '' : '<p>$caption</p>')
            : '<figure>${image(guideImagePath(language, picture), '../../', title)}'
                '${note == null ? '' : '<figcaption>$caption</figcaption>'}</figure>';
        return '''
<article class="step card">
  <h3><span class="step-number">${block['number']}</span> $title</h3>
  <p>$body</p>
  $illustration
</article>''';
      case 'p':
        return '<p>${text(block, 'text')}</p>';
      case 'tip':
      case 'warning':
        return '<aside class="$type"><p><strong>${ui(type as String)}.</strong> ${text(block, 'text')}</p></aside>';
      default:
        throw FormatException('Unknown guide block type: $type');
    }
  }
}

String icon(String name) {
  const paths = {
    'theme': 'M12 4a8 8 0 1 0 0 16V4Z M12 4a8 8 0 0 1 0 16',
    'check': 'M5 12l4 4L19 6',
    'download': 'M12 3v12m-5-5 5 5 5-5M5 17v3h14v-3',
    'stack': 'm3 7 9-4 9 4-9 4-9-4Zm0 5 9 4 9-4m-18 5 9 4 9-4',
    'book':
        'M12 6c-3-3-6-3-9-2v14c3-1 6-1 9 2 3-3 6-3 9-2V4c-3-1-6-1-9 2Zm0 0v14',
    'folder': 'M3 6h7l2 3h9v11H3V6Z',
    'lock': 'M7 10V7a5 5 0 0 1 10 0v3M5 10h14v11H5zm7 5v2',
    'heart': 'M20 6c-2-2-6-2-8 1-2-3-6-3-8-1-3 4 2 8 8 13 6-5 11-9 8-13Z',
    'android': 'M4 16a8 8 0 0 1 16 0v3H4Zm3-9L5 4m12 3 2-3M8 14h.1m7.9 0h.1',
    'windows': 'M3 5l18-2v18L3 19V5Zm0 7h18M11 4v16',
    'linux':
        'M9 8h6m-8 5L4 17l2 3h12l2-3-3-4m-10 6v-8c0-4 2-7 5-7s5 3 5 7v8M10 11l2 2 2-2',
  };
  return '<svg class="icon" viewBox="0 0 24 24" width="24" height="24" '
      'aria-hidden="true" fill="none" stroke="currentColor" stroke-width="1.7" '
      'stroke-linecap="round" stroke-linejoin="round"><path d="${paths[name]}"/></svg>';
}
