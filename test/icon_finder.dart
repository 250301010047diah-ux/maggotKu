import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maggotku/widgets/glyphs.dart';

/// Cari ikon, baik [Icon] Material maupun glyph [AppIcon] MaggotKu.
Finder findIcon(IconData icon) => find.byWidgetPredicate(
  (w) => (w is AppIcon && w.icon == icon) || (w is Icon && w.icon == icon),
);
