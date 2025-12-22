# 🔧 ThinkCyber App Icon Setup Guide

## 📱 **Android Icon Requirements**

### **Required Sizes (PNG format):**

1. **mipmap-mdpi/**: `ic_launcher.png` - **48x48 pixels**
2. **mipmap-hdpi/**: `ic_launcher.png` - **72x72 pixels**  
3. **mipmap-xhdpi/**: `ic_launcher.png` - **96x96 pixels**
4. **mipmap-xxhdpi/**: `ic_launcher.png` - **144x144 pixels**
5. **mipmap-xxxhdpi/**: `ic_launcher.png` - **192x192 pixels**

### **File Locations:**
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png      (48x48)
├── mipmap-hdpi/ic_launcher.png      (72x72)
├── mipmap-xhdpi/ic_launcher.png     (96x96)
├── mipmap-xxhdpi/ic_launcher.png    (144x144)
└── mipmap-xxxhdpi/ic_launcher.png   (192x192)
```

## 🍎 **iOS Icon Requirements**

### **Required Sizes (PNG format):**

Place in: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

1. **Icon-App-20x20@1x.png** - 20x20
2. **Icon-App-20x20@2x.png** - 40x40  
3. **Icon-App-20x20@3x.png** - 60x60
4. **Icon-App-29x29@1x.png** - 29x29
5. **Icon-App-29x29@2x.png** - 58x58
6. **Icon-App-29x29@3x.png** - 87x87
7. **Icon-App-40x40@1x.png** - 40x40
8. **Icon-App-40x40@2x.png** - 80x80
9. **Icon-App-40x40@3x.png** - 120x120
10. **Icon-App-60x60@2x.png** - 120x120
11. **Icon-App-60x60@3x.png** - 180x180
12. **Icon-App-76x76@1x.png** - 76x76
13. **Icon-App-76x76@2x.png** - 152x152
14. **Icon-App-83.5x83.5@2x.png** - 167x167
15. **Icon-App-1024x1024@1x.png** - 1024x1024

## 🛠️ **Easy Icon Generation Tools**

### **Option 1: Online Tools**
1. **App Icon Generator**: https://appicon.co/
   - Upload 1024x1024 PNG
   - Downloads all required sizes

2. **Icon Kitchen**: https://icon.kitchen/
   - Free Android/iOS icon generator

### **Option 2: Flutter Package**
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.1
```

Then add to `pubspec.yaml`:
```yaml
flutter_icons:
  android: true
  ios: true
  image_path: "Asset/app_icon.png"  # Your 1024x1024 icon
```

Run: `flutter pub get && flutter pub run flutter_launcher_icons:main`

## ✅ **Implementation Steps**

### **Step 1: Design Requirements**
- **Format**: PNG with transparent background
- **Base Size**: Create 1024x1024 pixels
- **Design**: Simple, recognizable, works at small sizes
- **Theme**: Cybersecurity/Shield/Lock related

### **Step 2: Generate All Sizes**
- Use online tool or flutter_launcher_icons package
- Ensure crisp edges at all resolutions

### **Step 3: Manual Placement (if not using package)**
- Copy files to respective Android mipmap folders
- Copy files to iOS Assets.xcassets folder
- Update Contents.json in iOS if needed

### **Step 4: Update Contents.json (iOS)**
Update `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`

### **Step 5: Build & Test**
```bash
flutter clean
flutter build apk --debug
# or
flutter build ios
```

## 🎨 **Icon Design Tips**

1. **Keep it simple** - Works at 48x48 pixels
2. **High contrast** - Readable on light/dark backgrounds  
3. **No text** - Use symbols/imagery only
4. **Brand colors** - Match ThinkCyber theme
5. **Test on device** - Check visibility on home screen

## 📋 **Current Status**
- ✅ App name changed to "ThinkCyber"
- ✅ Directory structure created
- 🔄 **NEXT**: Add your icon files to the directories above

---
*After placing icon files, run `flutter clean && flutter build apk` to see changes*