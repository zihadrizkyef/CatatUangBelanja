/// Shared across Wallet and Category (doc 2.4): an icon can come from the
/// bundled system icon set, a user-picked emoji, or an uploaded photo.
enum IconType {
  system,
  emoji,
  photo;

  static IconType fromName(String name) => IconType.values.byName(name);
}
