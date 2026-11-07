/// Photo slots used across the app. Drop JPG files with these exact names
/// into `assets/images/`. A missing file never crashes the app: each place
/// falls back to the green gradient and drawn illustration.
class AppImages {
  AppImages._();

  static const _dir = 'assets/images';

  /// Home carousel (landscape, about 1200 x 600 px).
  static const banner1 = '$_dir/banner_1.jpg';
  static const banner2 = '$_dir/banner_2.jpg';
  static const banner3 = '$_dir/banner_3.jpg';

  /// Welcome screen hero (portrait or square, about 1080 x 1200 px).
  static const welcomeHero = '$_dir/welcome_hero.jpg';

  /// Sign in / create account header (landscape, about 1200 x 500 px).
  static const authHeader = '$_dir/auth_header.jpg';
}
