# SecureBox App Icon

## Design
Cat holding a checkered gold/silver key (photo-realistic 3D render).

## Usage
This image is the official app icon for SecureBox.
Place the source image `app-icon.png` in this directory.

## Required sizes (Flutter / Android / iOS)

### Android (`android/app/src/main/res/`)
| Directory        | Size      |
|------------------|-----------|
| mipmap-mdpi      | 48x48     |
| mipmap-hdpi      | 72x72     |
| mipmap-xhdpi     | 96x96     |
| mipmap-xxhdpi    | 144x144   |
| mipmap-xxxhdpi   | 192x192   |

### iOS (`ios/Runner/Assets.xcassets/AppIcon.appiconset/`)
| Size    | Usage            |
|---------|------------------|
| 20x20   | Notification     |
| 29x29   | Settings         |
| 40x40   | Spotlight        |
| 60x60   | iPhone App       |
| 76x76   | iPad App         |
| 83.5x83.5 | iPad Pro      |
| 1024x1024 | App Store     |

### Recommended approach
Use `flutter_launcher_icons` package:

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.0

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app-icon.png"
  adaptive_icon_background: "#0d0d0d"
  adaptive_icon_foreground: "assets/icon/app-icon.png"
```

Then run:
```bash
dart run flutter_launcher_icons
```

## In-app usage
For the header logo and empty state icon, use a simplified SVG version
that captures the cat + key motif, matching the dark theme color scheme.
