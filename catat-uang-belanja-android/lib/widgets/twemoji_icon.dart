import 'package:flutter/widgets.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_icons.dart';

/// Shared render for any icon referenced by an `assets/icons/twemoji/*.svg`
/// path — used for both DB-backed category/wallet icons ([AppIcons.byIconValue])
/// and one-off UI icons ([AppIcons]'s named constants.
class TwemojiIcon extends StatelessWidget {
  const TwemojiIcon(this.asset, {super.key, this.size = 30});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(asset, width: size, height: size);
  }
}

@Preview(name: 'TwemojiIcon')
Widget previewTwemojiIcon() {
  return const TwemojiIcon(AppIcons.home, size: 48);
}
