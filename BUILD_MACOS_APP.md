# Exporting as a universal macOS app with icon

To export your finished game for macOS with an app that works for both Intel 64-bit and Apple Silicon and use a custom icon, you can use the included macOS_app_builder utility.

---

## Steps:
### 1. Exporting your app with Processing IDE
**_For detailed steps, visit [the Processing documentation](https://github.com/processing/processing4/wiki/Exporting-Applications#macos)._**
- Open your code project (/Source) in the Processing IDE.
- Go to ```File > Export Application...``` or press ```Cmd+Shift+E```.
- A menu should pop up with options to export for macOS (Intel 64-bit), macOS (Apple Silicon), Windows (Intel 64-bit), Linux (Intel 64-bit), Linux (Raspberry Pi 32-bit), and Linux (Raspberry Pi 64-bit).
- Check only macOS (Intel 64-bit) and macOS (Apple Silicon). Then, press **```Export```**.
- The folders ```macos-x86_64``` and ```macos-aarch64``` should appear in your ```Source``` folder.

### 2. Setting your custom icon
- Prepare your ```icon.png``` file. This should have a square aspect ratio. Ideally, it should be 512*512.
- Open your base folder, the parent folder of the ```/Source``` folder containing your .pde files. There should be a folder called ```/Application``` in it. If not, download it from this repository.
- In the ```/Application``` folder, look for the folder ```/icons```. If not present, create it.
- Move your ```icon.png``` file into the ```/icons``` folder.

### 3. Running the builder
- In the ```/Application``` folder, look for the folder ```/macOS_app_builder```. If not present, download it from the repository.
- Open the Terminal app on your Mac. Wait for it to load, then type the words ```cd ``` (with a space at the end).
- Then, without pressing Enter, drag the ```/macOS_app_builder``` folder into the window. Press Enter.
- Paste this command: ```chmod +x ./build_universal_app.sh``` and press Enter.
- Paste this command: ```./build_universal_app.sh``` and press Enter to start the builder.
- _**Optional:** If you want to change the name, bundle_id, copyright holder, etc. of the app, run the command with parameters like this:
```bash
APP_NAME="MyGame" \
BUNDLE_ID="com.example.mygame" \
COPYRIGHT_HOLDER="Jane Doe" \
COPYRIGHT_YEAR="2026" \
VERSION="1.0.0" \
ICON_PNG="icon.png" \
ICON_SIZE="512" \
DEVELOPER_ID="Developer ID Application: Jane Doe (TEAM12345)" \
APP_CATEGORY="public.app-category.games" \
SAVE_FILE_EXTENSIONS="json,save" \
./build_universal_app.sh
```
- Your app should be present in the ```/macOS_app_builder``` folder now, along with a .dmg file to easily move it to the ```/Applications``` folder.
