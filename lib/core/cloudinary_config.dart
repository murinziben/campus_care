/// Cloudinary settings for incident photos.
///
/// Both values come from the Cloudinary dashboard and are safe to keep in the
/// app: an *unsigned* upload preset is designed to be used from client apps
/// (no API secret is ever stored here).
///
///  - cloudName   : Dashboard -> top-left "Cloud name"
///  - uploadPreset: Settings -> Upload -> Upload presets -> Add preset
///                  (Signing mode = Unsigned, folder = incident_photos)
class CloudinaryConfig {
  CloudinaryConfig._();

  static const cloudName = 'chynvxsm';
  static const uploadPreset = 'campuscare_unsigned';

  static bool get isConfigured =>
      !cloudName.startsWith('YOUR_') && !uploadPreset.startsWith('YOUR_');
}
