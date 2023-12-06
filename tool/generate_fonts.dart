import 'dart:convert';
import 'dart:io';

import 'package:recase/recase.dart';
import 'package:xml/xml.dart';

import 'validation.dart';
import 'xml_to_map.dart';

void main(List<String> args) {
  final File fontsConfigFile = File('./fonts/SimpleIcons.ttx');
  final File colorsConfigFile = File('./fonts/simple-icons.json');

  if (!(fontsConfigFile.existsSync() && colorsConfigFile.existsSync())) {
    print('config files not found');
    exit(0);
  }

  final FontGenerator generator =
      FontGenerator(fontFile: fontsConfigFile, colorFile: colorsConfigFile);
  generator.createIconDataFile();
  generator.createIconColorFile();
}

class FontGenerator {
  FontGenerator({required this.fontFile, required this.colorFile}) {
    icons = _readIcons();
    colors = _readColors();
  }

  final File fontFile;
  final File colorFile;

  late final Map<String, String> icons;
  late final Map<String, String> colors;

  /// read the icon data from the [fontFile]
  Map<String, String> _readIcons() {
    final String content = fontFile.readAsStringSync();
    final XmlDocument document = XmlDocument.parse(content);

    final Map<String, String> icons = xmlToIcons(document).map((key, value) {
      final String iconNameValidated = validateVariableName(key);
      final String name = ReCase(iconNameValidated).camelCase;
      return MapEntry<String, String>(name, value);
    });
    return icons;
  }

  /// read the color data from the [colorFile]
  Map<String, String> _readColors() {
    final String content = colorFile.readAsStringSync();
    final List<dynamic> jsonList =
        jsonDecode(content)['icons'] as List<dynamic>;
    return Map<String, String>.fromEntries(jsonList.map((dynamic e) {
      final String iconNameValidated =
          validateVariableName(nameToSlug(e['title']));
      final String name = ReCase(iconNameValidated).camelCase;
      return MapEntry<String, String>(name, e['hex'].toLowerCase());
    }));
  }

  /// creates the icon_data.g.dart containing links to the font file
  void createIconDataFile() {
    final List<String> generatedOutput = <String>[
      "import 'package:flutter/widgets.dart';\n",
      "import 'icon_data.dart';\n\n",
      '// THIS FILE IS AUTOMATICALLY GENERATED!\n\n',
      '/// [SimpleIcons] offers the [IconData] of [https://simpleicons.org/]\n',
      'class SimpleIcons {\n'
    ];

    icons.forEach((String iconName, String iconUnicode) {
      generatedOutput.add(
          '''/// SimpleIcons $iconName [IconData] with Unicode $iconUnicode
          static const IconData $iconName = SimpleIconData($iconUnicode);\n''');
    });

    generatedOutput.add(
        '''\n\n
          /// [values] offers the [Map<String, IconData>] of [https://simpleicons.org/]
          static const Map<String, IconData> values = {\n
    ''');

    icons.forEach((String iconName, String iconUnicode) {
      generatedOutput.add('''
          '$iconName': SimpleIcons.$iconName,''');
    });

    generatedOutput.add('};\n\n');

    generatedOutput.add('}\n');

    final File fontFile = File('./lib/src/icon_data.g.dart');
    fontFile.writeAsStringSync(generatedOutput.join());
  }

  /// creates the icon_color.g.dart file which holds the icon's colors
  void createIconColorFile() {
    final List<String> generatedOutput = <String>[
      "import 'package:flutter/widgets.dart';\n\n",
      '// THIS FILE IS AUTOMATICALLY GENERATED!\n\n',
      '/// [SimpleIconColors] offers the [Color] of [https://simpleicons.org/]\'s icons\n',
      'class SimpleIconColors {\n'
    ];

    colors.forEach((String iconName, String colorHex) {
      generatedOutput.add(
          '''
  /// SimpleIcons $iconName [Color] from Hex $colorHex
  static const Color $iconName = Color(0xff$colorHex);\n''');
    });

    generatedOutput.add(
        '''\n\n
  /// [values] offers the [Map<String, Color>] of [https://simpleicons.org/]
  static const Map<String, Color> values = {\n
    ''');

    colors.forEach((String iconName, String colorHex) {
      generatedOutput
          .add('''
          '$iconName': SimpleIconColors.$iconName,''');
    });

    generatedOutput.add('};\n\n');
    generatedOutput.add('}\n');

    final File fontFile = File('./lib/src/icon_color.g.dart');
    fontFile.writeAsStringSync(generatedOutput.join());
  }
}
