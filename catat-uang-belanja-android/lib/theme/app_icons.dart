import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Bundled Twemoji SVGs (see assets/icons/twemoji/NOTICE.md for the required
/// CC-BY 4.0 attribution, also surfaced in SettingsScreen > Tentang
/// Aplikasi) so category/wallet/status icons render identically on every
/// device and OS, instead of depending on the platform's emoji font.
class AppIcons {
  AppIcons._();

  static const String _base = 'assets/icons/twemoji';

  static const String home = '$_base/house.svg';
  static const String wallet = '$_base/purse.svg';
  static const String summary = '$_base/bar_chart.svg';
  static const String settings = '$_base/gear.svg';

  static const String syncSynced = '$_base/check.svg';
  static const String syncSyncing = '$_base/arrows_counterclockwise.svg';
  static const String syncOffline = '$_base/cloud.svg';

  static const String budgetTarget = '$_base/dart.svg';
  static const String budgetSafe = '$_base/herb.svg';
  static const String budgetSeedling = '$_base/seedling.svg';
  static const String emptyReceipt = '$_base/receipt.svg';
  static const String appreciation = '$_base/party_popper.svg';

  static const String medal1 = '$_base/medal1.svg';
  static const String medal2 = '$_base/medal2.svg';
  static const String medal3 = '$_base/medal3.svg';

  static const String profileAvatar = '$_base/woman.svg';
  static const String darkMode = '$_base/crescent_moon.svg';
  static const String security = '$_base/lock.svg';
  static const String profile = '$_base/bust_in_silhouette.svg';
  static const String notification = '$_base/bell.svg';
  static const String categoryBudgetSetting = '$_base/label.svg';
  static const String language = '$_base/globe.svg';
  static const String help = '$_base/speech_balloon.svg';
  static const String about = '$_base/information.svg';

  /// Keyed by [Category.iconValue] / [Wallet.iconValue] as already seeded in
  /// `AppDatabase._seed` — the DB rows don't change, only how their
  /// `icon_value` string resolves to a rendered icon.
  static const Map<String, String> byIconValue = {
    'category_kitchen': '$_base/shopping_trolley.svg',
    'category_kids_snack': '$_base/lollipop.svg',
    'category_school': '$_base/school_satchel.svg',
    'category_arisan': '$_base/gift.svg',
    'category_bills': '$_base/bulb.svg',
    'category_health': '$_base/stethoscope.svg',
    'category_transport': '$_base/bus.svg',
    'category_entertainment': '$_base/clapper.svg',
    'category_salary': '$_base/briefcase.svg',
    'category_allowance': '$_base/love_letter.svg',
    'category_side_business': '$_base/shopping_bags.svg',
    'category_bonus': '$_base/party_popper.svg',
    'category_other': '$_base/sparkles.svg',
    'wallet_cash': '$_base/purse.svg',
    'wallet_bank': '$_base/bank.svg',
    'wallet_ewallet': '$_base/mobile_phone.svg',
  };
}

/// Shared render for any icon referenced by an `assets/icons/twemoji/*.svg`
/// path — used for both DB-backed category/wallet icons ([AppIcons.byIconValue])
/// and one-off UI icons ([AppIcons]'s named constants.
class TwemojiIcon extends StatelessWidget {
  const TwemojiIcon(this.asset, {super.key, this.size = 20});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(asset, width: size, height: size);
  }
}
