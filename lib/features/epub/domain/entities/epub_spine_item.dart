import 'package:meta/meta.dart';

/// An item reference in the `<spine>`, representing reading sequence.
@immutable
class EpubSpineItem {
  final String idref;
  final String fullPath;
  final int index;
  final bool isLinear;

  const EpubSpineItem({
    required this.idref,
    required this.fullPath,
    required this.index,
    this.isLinear = true,
  });

  @override
  String toString() =>
      'EpubSpineItem(index: $index, idref: $idref, fullPath: $fullPath, isLinear: $isLinear)';
}
