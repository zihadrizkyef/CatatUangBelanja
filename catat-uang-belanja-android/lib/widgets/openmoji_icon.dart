import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_icons.dart';

/// Shared render for any icon referenced by an `assets/icons/openmoji/*.svg`
/// path — used for both DB-backed category/wallet icons ([AppIcons.byIconValue])
/// and one-off UI icons ([AppIcons]'s named constants.
class OpenMojiIcon extends StatelessWidget {
  const OpenMojiIcon(this.asset, {super.key, this.size = 30});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(asset, width: size, height: size);
  }
}

@Preview(name: 'OpenMojiIcon')
Widget previewOpenMojiIcon() {
  return const OpenMojiIcon(AppIcons.home, size: 48);
}
