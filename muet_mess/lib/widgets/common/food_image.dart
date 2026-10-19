import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Maps dish names / backend image paths onto the bundled `assets/food/*.png`
/// files and caches which candidate actually resolves to a usable photo.
class FoodAssets {
  FoodAssets._();

  static const _dir = 'assets/food/';

  /// Images smaller than this (in either dimension) are treated as
  /// placeholders and replaced by the generated dish tile. Real photos
  /// dropped into `assets/food/` are picked up automatically.
  static const minPhotoPx = 96;

  /// candidate key -> resolved asset path (or null when nothing usable).
  static final Map<String, String?> cache = {};

  static const _tokenAliases = <String, String>{
    'qourma': 'qorma',
    'korma': 'qorma',
    'kurma': 'qorma',
    'karhai': 'karahi',
    'kadai': 'karahi',
    'karai': 'karahi',
    'dal': 'daal',
    'aalo': 'aloo',
    'alu': 'aloo',
    'egg': 'anda',
    'chawal': 'rice',
    'sabji': 'sabzi',
    'keema': 'qeema',
    'kaleji': 'kalegi',
    'omlette': 'omelette',
    'chhola': 'chholha',
    'chola': 'chholha',
    'cholay': 'chholha',
  };

  /// All tokens must be present in the dish name; first match wins.
  static const _rules = <(List<String>, String)>[
    (['aloo', 'biryani'], 'aalo_biryani'),
    (['chinese', 'biryani'], 'chinese_biryani'),
    (['chholha', 'biryani'], 'chholha_biryani'),
    (['beef', 'biryani'], 'beef_biryani'),
    (['biryani'], 'chicken_biryani'),
    (['beef', 'qorma', '130'], 'beef_qourma_130'),
    (['beef', 'qorma'], 'beef_qourma_120'),
    (['white', 'qorma'], 'white_qourma'),
    (['chicken', 'qorma'], 'chicken_qourma'),
    (['chicken', 'jalfrezi'], 'chicken_jalfrezi'),
    (['chicken', 'kalegi'], 'chicken_kalegi'),
    (['chicken', 'karahi'], 'chicken_karhai'),
    (['chicken', 'macaroni'], 'chicken_macaroni'),
    (['chicken', 'qeema'], 'chicken_qeema'),
    (['broast'], 'broast_with_fries'),
    (['anda', 'omelette'], 'anda_omelette'),
    (['omelette'], 'anda_omelette'),
    (['anda', 'gravy'], 'anda_gravy'),
    (['anda', 'qeema'], 'anda_qeema'),
    (['daal', 'rice'], 'daal_rice'),
    (['daal'], 'all_types_daal'),
    (['sabzi'], 'all_sabzi'),
    (['haleem'], 'haleem_rice'),
    (['fish'], 'fish'),
    (['paratha'], 'paratha'),
    (['rice', 'chicken'], 'rice_with_chicken_piece'),
  ];

  static List<String> tokens(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .split(' ')
        .where((t) => t.isNotEmpty)
        .map((t) => _tokenAliases[t] ?? t)
        .toList();
  }

  static String? fromName(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final t = tokens(name);
    for (final rule in _rules) {
      if (rule.$1.every(t.contains)) return '$_dir${rule.$2}.png';
    }
    return null;
  }

  /// Ordered list of asset paths worth trying for this dish.
  static List<String> candidates({String? path, String? name}) {
    final list = <String>[];
    if (path != null && path.isNotEmpty && !path.endsWith('default.png')) list.add(path);
    final byName = fromName(name);
    if (byName != null && !list.contains(byName)) list.add(byName);
    return list;
  }

  /// Icon that best represents a dish when no photo is available.
  static IconData iconFor(String name, String? category) {
    final t = tokens(name);
    bool has(List<String> words) => words.any(t.contains);
    final cat = (category ?? '').toLowerCase();
    if (has(['fish'])) return Icons.set_meal;
    if (has(['anda', 'omelette'])) return Icons.egg_alt;
    if (has(['macaroni', 'noodles', 'chowmein'])) return Icons.ramen_dining;
    if (has(['biryani', 'pulao', 'rice', 'haleem'])) return Icons.rice_bowl;
    if (has(['chai', 'tea', 'coffee', 'lassi', 'juice']) || cat.contains('bever')) return Icons.local_cafe;
    if (has(['roti', 'paratha', 'naan', 'bread']) || cat.contains('bread')) return Icons.bakery_dining;
    if (has(['salad', 'raita', 'sabzi', 'vegetable']) || cat.contains('side')) return Icons.eco;
    if (has(['chicken', 'beef', 'qorma', 'karahi', 'qeema', 'jalfrezi', 'kalegi', 'broast'])) {
      return Icons.dinner_dining;
    }
    if (cat.contains('breakfast')) return Icons.free_breakfast;
    if (cat.contains('lunch')) return Icons.lunch_dining;
    if (cat.contains('dinner')) return Icons.dinner_dining;
    return Icons.restaurant;
  }
}

/// A dish picture. Shows the real photo when one is bundled, otherwise a
/// polished, name-tinted tile with a matching icon.
class FoodImage extends StatefulWidget {
  const FoodImage({
    super.key,
    this.path,
    this.name,
    this.category,
    this.size = 44,
    this.fill = false,
    this.radius = 12,
    this.grayscale = false,
  });

  /// Backend-provided asset path (may be missing / default).
  final String? path;

  /// Dish name; used to find a matching asset and to tint the fallback tile.
  final String? name;
  final String? category;
  final double size;

  /// Fill the parent's constraints instead of using [size].
  final bool fill;
  final double radius;
  final bool grayscale;

  @override
  State<FoodImage> createState() => _FoodImageState();
}

class _FoodImageState extends State<FoodImage> {
  String? _asset;
  List<String> _candidates = const [];
  String _key = '';
  int _index = 0;
  bool _sync = false;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _start();
  }

  @override
  void didUpdateWidget(FoodImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path || oldWidget.name != widget.name) _start();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _stop() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) stream.removeListener(listener);
    _stream = null;
    _listener = null;
  }

  void _start() {
    _stop();
    _candidates = FoodAssets.candidates(path: widget.path, name: widget.name);
    _key = _candidates.join('|');
    if (FoodAssets.cache.containsKey(_key)) {
      _asset = FoodAssets.cache[_key];
      return;
    }
    _asset = null;
    _index = 0;
    _sync = true;
    _tryNext();
    _sync = false;
  }

  void _tryNext() {
    if (_index >= _candidates.length) {
      FoodAssets.cache[_key] = null;
      return;
    }
    final candidate = _candidates[_index];
    final stream = AssetImage(candidate).resolve(createLocalImageConfiguration(context));
    final listener = ImageStreamListener(
      (info, _) {
        final ok = info.image.width >= FoodAssets.minPhotoPx && info.image.height >= FoodAssets.minPhotoPx;
        info.dispose();
        if (_stream == stream) _stop();
        if (ok) {
          FoodAssets.cache[_key] = candidate;
          if (_sync) {
            _asset = candidate;
          } else if (mounted) {
            setState(() => _asset = candidate);
          }
        } else {
          _index++;
          _tryNext();
        }
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (_stream == stream) _stop();
        _index++;
        _tryNext();
      },
    );
    _stream = stream;
    _listener = listener;
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.name ?? '';
    final tile = _DishTile(name: name, category: widget.category);
    final dimension = widget.fill ? double.infinity : widget.size;

    Widget content;
    final asset = _asset;
    if (asset != null) {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      content = Image.asset(
        asset,
        width: dimension,
        height: dimension,
        fit: BoxFit.cover,
        cacheWidth: widget.fill ? 640 : (widget.size * dpr).round(),
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        semanticLabel: widget.name,
        errorBuilder: (_, __, ___) => tile,
      );
    } else {
      content = tile;
    }

    if (widget.grayscale) {
      content = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: content,
      );
    }

    final box = widget.fill
        ? SizedBox.expand(child: content)
        : SizedBox(width: widget.size, height: widget.size, child: content);
    return ClipRRect(borderRadius: BorderRadius.circular(widget.radius), child: box);
  }
}

/// Generated fallback: soft two-tone gradient (hue from the dish name) with a
/// food icon.
class _DishTile extends StatelessWidget {
  const _DishTile({required this.name, this.category});

  final String name;
  final String? category;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    var hash = 11;
    for (final unit in name.toLowerCase().codeUnits) {
      hash = (hash * 31 + unit) % 360;
    }
    final hue = hash.toDouble();
    final start = HSLColor.fromAHSL(1, hue, 0.55, dark ? 0.22 : 0.93).toColor();
    final end = HSLColor.fromAHSL(1, (hue + 24) % 360, 0.5, dark ? 0.3 : 0.85).toColor();
    final iconColor = HSLColor.fromAHSL(1, hue, 0.5, dark ? 0.78 : 0.36).toColor();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [start, end]),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final shortest = constraints.biggest.shortestSide;
        final base = shortest.isFinite ? shortest : 48.0;
        final iconSize = math.min(math.max(base * 0.46, 16.0), 56.0);
        return Center(child: Icon(FoodAssets.iconFor(name, category), size: iconSize, color: iconColor));
      }),
    );
  }
}
