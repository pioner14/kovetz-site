import 'dart:convert';
import 'dart:io';

const guideLanguages = {'ru': 'Русский', 'en': 'English'};

typedef GuideData = Map<String, dynamic>;

GuideData readData(String path) =>
    jsonDecode(File(path).readAsStringSync()) as GuideData;

GuideData readGuide(Directory source, String language) =>
    readData('${source.path}/guide.$language.json');

List<GuideData> guideEntries(GuideData parent, String key) =>
    (parent[key] as List<dynamic>).cast<GuideData>();

String guideImagePath(String language, String image) =>
    'guide/$language/$image.png';
