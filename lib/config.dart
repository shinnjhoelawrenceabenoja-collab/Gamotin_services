/// Server address. Override at build time:
/// flutter build apk --dart-define=API_URL=https://your-server.com
/// (10.0.2.2 = your computer when using the Android emulator)
const String kBaseUrl =
    String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8080');

const List<String> kPaperSizes = [
  'A0', 'A1', 'A2', 'A3', 'A4', 'A5', 'A6',
  'B4', 'B5',
  'Short (8.5x11)', 'Long (8.5x13)', 'Legal (8.5x14)', 'Letter',
  'Folio', 'Tabloid (11x17)',
  '2R (2.5x3.5)', '3R (3.5x5)', '4R (4x6)', '5R (5x7)', '6R (6x8)', '8R (8x10)',
  'ID Photo / Wallet',
];

const List<String> kPaperTypes = [
  'Normal Bond Paper', 'Photo Paper (Glossy)', 'Photo Paper (Matte)',
  'Matte Paper', 'Glossy Paper', 'Cardstock', 'Sticker Paper',
  'Special / Textured Paper', 'Tracing Paper', 'Recycled Paper',
];
