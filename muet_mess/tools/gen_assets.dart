// Generates simple colored placeholder PNGs for each food item so the
// UI has a distinct image per item. Replace with real photos later;
// just keep the same file names.
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

int crc32(List<int> data) {
  var c = 0xFFFFFFFF;
  for (final b in data) {
    c ^= b;
    for (var i = 0; i < 8; i++) {
      c = (c & 1) != 0 ? (c >> 1) ^ 0xEDB88320 : c >> 1;
    }
  }
  return c ^ 0xFFFFFFFF;
}

Uint8List chunk(String type, List<int> data) {
  final len = ByteData(4)..setUint32(0, data.length);
  final typeBytes = ascii.encode(type);
  final crc = ByteData(4)..setUint32(0, crc32([...typeBytes, ...data]));
  return Uint8List.fromList([...len.buffer.asUint8List(), ...typeBytes, ...data, ...crc.buffer.asUint8List()]);
}

void main() {
  final names = <String>[
    'chicken_biryani', 'chicken_qourma', 'chicken_karhai', 'all_sabzi', 'daal_rice',
    'haleem_rice', 'beef_biryani', 'chholha_biryani', 'aalo_biryani', 'all_types_daal',
    'chicken_jalfrezi', 'chinese_biryani', 'chicken_qeema', 'white_qourma', 'chicken_kalegi',
    'fish', 'beef_qourma_120', 'anda_qeema', 'rice_with_chicken_piece', 'broast_with_fries',
    'beef_qourma_130', 'anda_gravy', 'chicken_macaroni', 'paratha', 'anda_omelette',
  ];
  Directory('assets/food').createSync(recursive: true);
  const size = 64;
  for (var i = 0; i < names.length; i++) {
    final r = (i * 37 + 80) % 256;
    final g = (i * 91 + 60) % 256;
    final b = (i * 53 + 120) % 256;
    final raw = <int>[];
    for (var y = 0; y < size; y++) {
      raw.add(0);
      for (var x = 0; x < size; x++) {
        raw.addAll([r, g, b]);
      }
    }
    final idat = ZLibCodec().encode(raw);
    final ihdr = ByteData(13)
      ..setUint32(0, size)
      ..setUint32(4, size)
      ..setUint8(8, 8)
      ..setUint8(9, 2)
      ..setUint8(10, 0)
      ..setUint8(11, 0)
      ..setUint8(12, 0);
    final png = BytesBuilder()
      ..add([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
      ..add(chunk('IHDR', ihdr.buffer.asUint8List()))
      ..add(chunk('IDAT', idat))
      ..add(chunk('IEND', []));
    File('assets/food/${names[i]}.png').writeAsBytesSync(png.toBytes());
  }
  // ignore: avoid_print
  print('Generated ${names.length} images in assets/food/');
}
