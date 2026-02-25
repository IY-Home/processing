class KeyManager {
    int KEY_COUNT = 256;
    boolean[] keys = new boolean[KEY_COUNT];
    
    void setKeyPressed(int keyCode, boolean pressed) {
        if (keyCode >= 0 && keyCode < KEY_COUNT) {
            keys[keyCode] = pressed;
        }
    }
    
    boolean isKeyPressed(int keyCode) {
        if (keyCode >= 0 && keyCode < KEY_COUNT) {
            return keys[keyCode];
        }
        return false;
    }
    
    void resetAllKeys() {
        Arrays.fill(keys, false);
    }
}


// Handle key presses
void keyPressed() {
    gameManager.keyManager.setKeyPressed(keyCode, true);
    
    // First, let input boxes handle keys
    boolean handledByInputBox = false;
    for (int i = gameManager.activeInputBoxes.size() - 1; i >= 0; i--) {
        InputBox box = gameManager.activeInputBoxes.get(i);
        if (box.isVisible()) {
            box.keyDown(key, keyCode);
            handledByInputBox = true;
            break; // Only one input box active at a time
        }
    }
    
    // If not handled by input box, process game keys
    if (!handledByInputBox) {
        // Existing drone controls
        for (Thing obj: gameManager.objects) {
            if (obj instanceof keyEvents) {
                ((keyEvents) obj).keyDown(key, keyCode);
            }
        }
    }
}
// Handle key releases
void keyReleased() {
    gameManager.keyManager.setKeyPressed(keyCode, false);
    if (gameManager.activeInputBoxes.size() == 0) {
        for (Thing obj: gameManager.objects) {
            if (obj instanceof keyEvents) {
                ((keyEvents) obj).keyUp(key, keyCode);
            }
        }
    }
}

void mousePressed() {
  gameManager.messageBox.onMousePressed();
}
void mouseDragged() {
  gameManager.messageBox.onMouseDragged();
}
void mouseReleased() {
  gameManager.messageBox.onMouseReleased();
}
