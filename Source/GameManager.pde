import java.util.*;
import java.time.LocalDateTime;

class GameManager {
    String programName;
    String version;
    String startupMessage;
  
    // Core collections
    ArrayList<Thing> objects;
    ArrayList<Human> mainHumans;
    ArrayList<InputBox> activeInputBoxes;

    Human trackedHuman = null; // Follow the scene of that human 
         
    // Systems
    Window window;
    KeyManager keyManager;
    ImageManager imageManager;
    SaveManager saveManager;
    MessageBox messageBox;
    
    boolean useSaveSystem = true;
    
    GameManager(String programName, String programVersion) {
        this.programName = programName;
        this.version = programVersion;
        startupMessage = "### " + programName + " v" + version + " ###";  
        objects = new ArrayList<Thing>();
        mainHumans = new ArrayList<Human>();
        activeInputBoxes = new ArrayList<InputBox>();
        imageManager = new ImageManager();
        window = new Window(imageManager, color(255), color(50), 1);
        keyManager = new KeyManager();
        saveManager = new SaveManager();
        messageBox = new MessageBox(
            width * 0.15,  // 15% from left
            height * 0.10, // 75% from top (near bottom)
            width * 0.7,   // 70% of screen width
            height * 0.15  // 15% of screen height
        );
        messageBox.maxMessages = 3;
        messageBox.visible = false;
    }

    void init() {
        println(startupMessage);
        println("Initializing GameManager...");
        
        // Clear existing state
        objects.clear();
        mainHumans.clear();
        activeInputBoxes.clear();
        window.scenes.clear();
        keyManager.resetAllKeys();
        
        // Initialize game
        createScenes(window);
        createHumans(mainHumans);
        createObjects(objects);
        if (useSaveSystem) {
          setObjectIDs();
          loadGame();
        }
        imageManager.startLoading();
        
        println("GameManager initialized!");
    }
    
    void update() {
        window.drawBackground();
        updateThings();
        window.drawCursor(window.cursorSize, window.cursorColor);
        messageBox.update();
        messageBox.display();
        loop();
    }
    
    void updateThings() {
        // Draw background objects first
        for (Thing obj : objects) {
            if (obj.drawBehindHumans && obj.inScene() && obj.show) {
                push();
                obj.display();
                pop();
            }
        }
        
        // Update humans
        for (Human human : mainHumans) {
            if (human == trackedHuman) {                     
                if (human.sceneIn != this.window.scene) {
                    this.window.goToScene(human.sceneIn);
                }
            }
            if (human.inScene()) {
                push();
                human.live();
                if (human == trackedHuman) {
                    // Indicate tracked human
                    noFill();
                    stroke(0, 255, 0);
                    strokeWeight(4);
                    ellipse(human.position.x, human.position.y - human.trackedIndicatorHeight, 10, 10);
                }
                pop();
            }
        }
        
        for (Thing obj : objects) {
            if (obj.drawInBackground && !obj.drawBehindHumans && obj.inScene() && obj.show) {
                push();
                obj.display();
                pop();
            }
        }
        
        // Update and check collisions for all objects
        for (int i = 0; i < objects.size(); i++) {
            Thing obj = objects.get(i);
            if (obj != null && obj.inScene()) {
                if (!(obj instanceof Human)) {
                    obj.update();
                    if (!obj.drawInBackground && !obj.drawInForeground && !obj.drawBehindHumans && obj.show) {
                        push();
                        obj.display();
                        pop();
                    }
                    obj.checkEdges();
                } else ((Human)obj).live();
                
                // Check collisions with other objects
                for (int j = 0; j < objects.size(); j++) {
                    Thing other = objects.get(j);
                    if (other != null && other != obj && other.inScene() &&
                        ((obj.checkTouchY && (PVector.dist(obj.position, other.position) < 200 || obj.checkTouchWide)) || 
                         (!obj.checkTouchY && (abs(other.position.x - obj.position.x) < 200 || obj.checkTouchWide)))) {
                        obj.checkTouch(other);
                    }
                }
                
                // Check collisions with humans
                for (Human human : mainHumans) {
                    if (human != null && human.inScene() && obj != human) {
                        float dist = obj.checkTouchY ? 
                            PVector.dist(obj.position, human.position) : 
                            abs(obj.position.x - human.position.x);
                        if (dist < 250 || obj.checkTouchWide) {
                            obj.checkTouch(human);
                            human.checkTouch(obj);
                        }
                    }
                }
            } else if (obj != null && obj.sceneIn == window.trashScene) {
                obj.show = false;
            } else if (obj != null && !obj.inScene() && obj.updateInBackground) {
                obj.backgroundUpdate();
            }
        }
        // Finally, draw objects in the front
        for (Thing obj : objects) {
            if (obj.drawInForeground && !obj.drawInBackground && !obj.drawBehindHumans && obj.inScene() && obj.show) {
                push();
                obj.display();
                pop();
            }
        }
        // Update input boxes
        for (InputBox box : activeInputBoxes) {
            box.update();
        }
    }
    
    // Utility methods
    boolean in(Thing testObj) {
        return objects.contains(testObj);
    }
    
    void removeThing(Thing testObj) {
        if (objects.contains(testObj)) {
            objects.remove(testObj);
        }
    }
    
    void addThing(Thing obj) {
        if (!objects.contains(obj)) {
            objects.add(obj);
        }
    }
    
    void addHuman(Human human) {
        if (!mainHumans.contains(human)) {
            mainHumans.add(human);
        }
    }
    
    void saveGame() {
      saveManager.saveGame();
    }

    void loadGame() {
      saveManager.loadGame();
    }
    
    void setObjectIDs() {
      for (Thing obj : objects) {
          obj.id = saveManager.getNextID();
      }
      for (Human human : mainHumans) {
          if (!objects.contains(human)) {
              human.id = saveManager.getNextID();
              println("    Human (" + human.getClass().getSimpleName() + ") " + human.name + " assigned ID: " + human.id);
          }
      }
       println("    Assigned IDs to objects and humans from ID 1 to " + saveManager.currentMaxID);
    }
}


public class CircularArrayList<E> extends ArrayList<E> {
    private boolean loop = true;
    private E returnValue = null;
    
    @Override
    public E get(int index) {
        if (loop && !isEmpty()) {
            return super.get(index % size());
        } else {
            if (index >= 0 && index < size()) {
                return super.get(index);
            }
            return returnValue;
        }
    }
    
    // Type-safe getters with defaults
    public <T> T getAs(int index, Class<T> type, T defaultValue) {
        E value = get(index);
        if (type.isInstance(value)) {
            return type.cast(value);
        }
        return defaultValue;
    }
    
    public <T> T getAs(int index, Class<T> type) {
        return getAs(index, type, null);
    }
    
    // Check type without getting
    public boolean isType(int index, Class<?> type) {
        if (index < 0 || index >= size()) return false;
        return type.isInstance(get(index));
    }
    
    public void setLoop(boolean loop) {
        this.loop = loop;
    }
    
    public void setDefaultReturnValue(E returnValue) {
        this.returnValue = returnValue;
    }
}



class Window {
    CircularArrayList<Object> scenes;  // Can hold colors (Integer) or STRING IDs for images
    ArrayList<Boolean> sceneHasGround; // Parallel list to scenes
    
    // Terrain ground system - keyframes per scene
    ArrayList<ArrayList<GroundKeyframe>> sceneGroundKeyframes;
    float defaultGroundHeight = 0.8;
    float groundHeightSampleRate = 5;
    color groundColor;
    
    boolean drawingCustomCursor = false;
    boolean useSystemCursor = false;
    float cursorSize;
    color cursorColor;
      
    int scene = 0;
    boolean loopScenes = false; 
    float frameSpeed;
    
    int trashScene = 999;
    
    ImageManager imageManager; // Reference to ImageManager

    // Constructor
    Window(ImageManager imageManager, color backgroundColor, color groundColor, float speed) {
        this.groundColor = groundColor;
        this.frameSpeed = speed;
        this.scenes = new CircularArrayList<Object>();
        this.sceneHasGround = new ArrayList<Boolean>();
        this.sceneGroundKeyframes = new ArrayList<ArrayList<GroundKeyframe>>();
        this.cursorSize = 20;
        this.scenes.setLoop(loopScenes);
        this.scenes.setDefaultReturnValue(backgroundColor);
        this.imageManager = imageManager;
    }
    
    // Keyframe class to store terrain points
    class GroundKeyframe {
        float x;           // Screen X coordinate (0 to width)
        float height;      // Ground height (0.0 to 1.0, fraction of screen height)
        
        GroundKeyframe(float x, float height) {
            this.x = constrain(x, 0, width);
            this.height = constrain(height, 0.1, 0.95); // Reasonable bounds
        }
    }

    // Add scenes in bulk
    void addScenes(Object[] sceneArray, Boolean[] groundArray) {
        for (int i = 0; i < sceneArray.length; i++) {
            // If it's a String (image path), queue it in ImageManager
            if (sceneArray[i] instanceof String) {
                String path = (String) sceneArray[i];
                imageManager.addImage(path, path, width, height);
                scenes.add(path); // Store the path as ID
            } else {
                scenes.add(sceneArray[i]); // Store color directly
            }
            
            if (groundArray[i] != null) { 
                sceneHasGround.add(groundArray[i]); 
            } else {  
                sceneHasGround.add(true); 
            }
            
            // Initialize keyframes for this scene with default flat ground
            ArrayList<GroundKeyframe> defaultKeyframes = new ArrayList<GroundKeyframe>();
            defaultKeyframes.add(new GroundKeyframe(0, defaultGroundHeight));
            defaultKeyframes.add(new GroundKeyframe(width, defaultGroundHeight));
            sceneGroundKeyframes.add(defaultKeyframes);
        }
    }
    
    // Convenience method for when all have same ground setting
    void addScenes(Object[] sceneArray, boolean allHaveGround) {
        for (Object sceneObj : sceneArray) {
            if (sceneObj instanceof String) {
                String path = (String) sceneObj;
                imageManager.addImage(path, path, width, height);
                scenes.add(path);
            } else {
                scenes.add(sceneObj);
            }
            sceneHasGround.add(allHaveGround);
            
            // Initialize keyframes for this scene with default flat ground
            ArrayList<GroundKeyframe> defaultKeyframes = new ArrayList<GroundKeyframe>();
            defaultKeyframes.add(new GroundKeyframe(0, defaultGroundHeight));
            defaultKeyframes.add(new GroundKeyframe(width, defaultGroundHeight));
            sceneGroundKeyframes.add(defaultKeyframes);
        }
    }
    
    void setSceneGround(int sceneIndex, boolean hasGround) {
        if (sceneIndex >= 0 && sceneIndex < sceneHasGround.size()) {
            sceneHasGround.set(sceneIndex, hasGround);
        }
    }
    
    // Add a ground keyframe for a specific scene
    void addGroundKeyframe(int sceneIndex, float x, float height) {
        if (sceneIndex < 0 || sceneIndex >= sceneGroundKeyframes.size()) return;
        
        ArrayList<GroundKeyframe> keyframes = sceneGroundKeyframes.get(sceneIndex);
        
        // Remove any existing keyframe at roughly this x
        keyframes.removeIf(kf -> abs(kf.x - x) < 0.1);
        
        // Add new keyframe
        keyframes.add(new GroundKeyframe(x, height));
        
        // Sort by x coordinate
        keyframes.sort((a, b) -> Float.compare(a.x, b.x));
    }
    
    // Remove all ground keyframes for a scene (reverts to flat)
    void resetGroundKeyframes(int sceneIndex) {
        if (sceneIndex < 0 || sceneIndex >= sceneGroundKeyframes.size()) return;
        
        ArrayList<GroundKeyframe> keyframes = sceneGroundKeyframes.get(sceneIndex);
        keyframes.clear();
        keyframes.add(new GroundKeyframe(0, defaultGroundHeight));
        keyframes.add(new GroundKeyframe(width, defaultGroundHeight));
    }
    
    // Get ground height at specific X coordinate for current scene
    float getGroundHeightAt(int scene, float x) {
        if (scene < 0 || scene >= sceneGroundKeyframes.size()) {
            return defaultGroundHeight;
        }
        
        ArrayList<GroundKeyframe> keyframes = sceneGroundKeyframes.get(scene);
        if (keyframes.isEmpty()) return defaultGroundHeight;
        
        // Clamp x to screen bounds
        x = constrain(x, 0, width);
        
        // Find surrounding keyframes
        GroundKeyframe left = null;
        GroundKeyframe right = null;
        
        for (GroundKeyframe kf : keyframes) {
            if (kf.x <= x) left = kf;
            if (kf.x >= x && right == null) right = kf;
        }
        
        // Handle edges
        if (left == null) return right.height;
        if (right == null) return left.height;
        if (left == right) return left.height;
        
        // Linear interpolation between keyframes
        float t = (x - left.x) / (right.x - left.x);
        return lerp(left.height, right.height, t);
    }
    
    float getGroundHeightAt(float x) {
        if (scene < 0 || scene >= sceneGroundKeyframes.size()) {
            return defaultGroundHeight;
        }
        
        ArrayList<GroundKeyframe> keyframes = sceneGroundKeyframes.get(scene);
        if (keyframes == null || keyframes.isEmpty()) {
            return defaultGroundHeight;
        }
        
        // Clamp x to screen bounds
        x = constrain(x, 0, width);
        
        // Find surrounding keyframes
        GroundKeyframe left = null;
        GroundKeyframe right = null;
        
        for (GroundKeyframe kf : keyframes) {
            if (kf.x <= x) left = kf;
            if (kf.x >= x && right == null) right = kf;
        }
        
        // Handle edges
        if (left == null && right != null) return right.height;
        if (right == null && left != null) return left.height;
        if (left == null && right == null) return defaultGroundHeight;
        
        // If left and right are the same keyframe (x exactly at keyframe)
        if (left == right || abs(left.x - right.x) < 0.0001) {
            return left.height; // Just return the height at that point
        }
        
        // Safe interpolation
        float t = (x - left.x) / (right.x - left.x);
        return lerp(left.height, right.height, t);
    }
    
    float getGroundAngleAt(float x) {
        float epsilon = 1; // Small offset for derivative
        
        // Constrain x to valid range
        x = constrain(x, epsilon, width - epsilon);
        
        float y1 = getGroundHeightAt(x - epsilon);
        float y2 = getGroundHeightAt(x + epsilon);
        
        // Calculate angle in radians
        // Note: dy is (y2 - y1) * height to convert to pixels
        float dy = (y2 - y1) * height;
        float dx = epsilon * 2;
        
        return atan2(dy, dx);
    }
    
    float getGroundNormalX(float x) {
        float angle = getGroundAngleAt(x);
        return -sin(angle); // Perpendicular to surface
    }
    
    float getGroundNormalY(float x) {
        float angle = getGroundAngleAt(x);
        return cos(angle); // Perpendicular to surface
    }
    
    // Draw ground with variable height
    void drawGround() {
        if (!sceneHasGround.get(scene)) return;
        
        stroke(0);
        strokeWeight(1.5);
        fill(groundColor);
        
        // Draw ground as a polygon following the terrain
        beginShape();
        
        // Start at bottom-left corner
        vertex(0, height);
        
        // Add vertices for each ground point
        float step = groundHeightSampleRate;
        for (float x = 0; x <= width; x += step) {
            float groundY = height * getGroundHeightAt(x);
            vertex(x, groundY);
        }
        
        // End at bottom-right corner
        vertex(width, height);
        
        endShape(CLOSE);
    }
    
    void createStairs(int sceneIndex, float startX, float endX, 
                      float startHeight, float endHeight, 
                      float stepWidth, float stepHeight) {
        
        ArrayList<GroundKeyframe> keyframes = sceneGroundKeyframes.get(sceneIndex);
        
        float x = startX - stepWidth;
        float currentHeight = startHeight;
        float stepX = (endX > startX) ? stepWidth : -stepWidth;
        float stepY = (endHeight > startHeight) ? stepHeight : -stepHeight;
        
        // Add start point
        keyframes.add(new GroundKeyframe(x, startHeight));
        
        // Create steps
        while (abs(x - startX) < abs(endX - startX)) {
            // Horizontal platform
            float nextX = x + stepX;
            keyframes.add(new GroundKeyframe(nextX, currentHeight));
            
            // Vertical riser (with tiny offset)
            currentHeight += stepY;
            float verticalX = nextX + 1; // 1 pixel offset
            keyframes.add(new GroundKeyframe(verticalX, currentHeight));
            
            x = nextX;
        }
        
        // Sort keyframes
        keyframes.sort((a, b) -> Float.compare(a.x, b.x));
    }
    
    // Draw small markers at keyframe positions (for debugging)
    void drawKeyframeMarkers() {
        if (scene < 0 || scene >= sceneGroundKeyframes.size()) return;
        
        ArrayList<GroundKeyframe> keyframes = sceneGroundKeyframes.get(scene);
        
        pushStyle();
        stroke(255, 0, 0);
        strokeWeight(4);
        fill(255, 0, 0, 100);
        
        for (GroundKeyframe kf : keyframes) {
            float markerX = kf.x;
            float markerY = height * kf.height;
            
            // Draw cross at keyframe
            line(markerX - 8, markerY - 8, markerX + 8, markerY + 8);
            line(markerX - 8, markerY + 8, markerX + 8, markerY - 8);
            
            // Draw height label
            fill(255, 0, 0);
            textSize(12);
            text(nf(kf.height, 1, 2), markerX + 15, markerY - 10);
        }
        
        popStyle();
    }

    void drawBackground() {
        // Draw scene background DIRECTLY from ImageManager
        Object currentSceneObj = scenes.get(scene);
        
        if (currentSceneObj instanceof String) {
            // It's an image path - get from ImageManager
            String imageId = (String) currentSceneObj;
            PGraphics img = imageManager.getImage(imageId);
            
            if (img != null) {
                // Draw directly from ImageManager!
                image(img, 0, 0, width, height);
            } else {
                // Fallback if image not loaded yet
                background(100, 0, 100); // Purple error color
                fill(255);
                textSize(32);
                textAlign(CENTER, CENTER);
                text("Loading: " + imageId, width/2, height/2);
            }
        } else if (currentSceneObj instanceof Integer) {
            // Draw color
            background((Integer)currentSceneObj);
        } else if (currentSceneObj instanceof PImage) {
            // Legacy support for direct PImage
            image((PImage)currentSceneObj, 0, 0, width, height);
        } else {
            background(100);
        }
        
        // Draw ground
        drawGround();
        
        frameRate(this.frameSpeed * 60);
    }
    
    // Helper methods for easy scene management
    void addScene(color c, Boolean t) {
        scenes.add(c);
        sceneHasGround.add(t);
        // Initialize keyframes for this scene
        ArrayList<GroundKeyframe> defaultKeyframes = new ArrayList<GroundKeyframe>();
        defaultKeyframes.add(new GroundKeyframe(0, defaultGroundHeight));
        defaultKeyframes.add(new GroundKeyframe(width, defaultGroundHeight));
        sceneGroundKeyframes.add(defaultKeyframes);
    }
    
    void addScene(PImage img, Boolean t) {
        scenes.add(img);
        sceneHasGround.add(t);
        // Initialize keyframes for this scene
        ArrayList<GroundKeyframe> defaultKeyframes = new ArrayList<GroundKeyframe>();
        defaultKeyframes.add(new GroundKeyframe(0, defaultGroundHeight));
        defaultKeyframes.add(new GroundKeyframe(width, defaultGroundHeight));
        sceneGroundKeyframes.add(defaultKeyframes);
    }
    
    // Add scene with image path (uses ImageManager)
    void addScene(String imagePath, Boolean t) {
        imageManager.addImage(imagePath, imagePath, width, height);
        scenes.add(imagePath);
        sceneHasGround.add(t);
        // Initialize keyframes for this scene
        ArrayList<GroundKeyframe> defaultKeyframes = new ArrayList<GroundKeyframe>();
        defaultKeyframes.add(new GroundKeyframe(0, defaultGroundHeight));
        defaultKeyframes.add(new GroundKeyframe(width, defaultGroundHeight));
        sceneGroundKeyframes.add(defaultKeyframes);
    }
    
    void goToScene(int newScene) {
        if (this.scene != newScene) {
            this.scene = newScene;
        }
    }
    
    // Draw custom cursor
    void drawCursor(float size, color cursorColor) {
      if (!useSystemCursor && !drawingCustomCursor) {
        this.cursorSize = size;
        this.cursorColor = cursorColor;
        noCursor();
        fill(this.cursorColor);
        stroke(0);
        ellipse(mouseX, mouseY, this.cursorSize, this.cursorSize);
      }
    }
    
    void drawCustomCursor(Runnable cursorDrawer) {
      if (!useSystemCursor && drawingCustomCursor) {
        noCursor();
        push();
        cursorDrawer.run();
        pop();
        noCursor();
      }
    }
}

class ImageManager {  
    // Image storage
    HashMap<String, PGraphics> images = new HashMap<String, PGraphics>();
    
    // Loading queue
    ArrayList<LoadRequest> queue = new ArrayList<LoadRequest>();
    int totalAssets = 0;
    int loadedAssets = 0;
    
    ImageManager() {
    }
    
    PGraphics createPlaceholder(int w, int h) {
        PGraphics placeholder;
        color placeholderColor1 = color(255, 0, 255); // Magenta
        color placeholderColor2 = color(0, 255, 255); // Cyan
        color placeholderTextColor = color(255);
        
        placeholder = createGraphics(w, h);
        placeholder.beginDraw();
        
        // Draw checkerboard pattern
        placeholder.background(placeholderColor1);
        placeholder.fill(placeholderColor2);
        
        int cellSize = 20;
        for (int x = 0; x < w; x += cellSize) {
            for (int y = 0; y < h; y += cellSize) {
                if ((x/cellSize + y/cellSize) % 2 == 0) {
                    placeholder.rect(x, y, cellSize, cellSize);
                }
            }
        }
        
        // Draw "?" symbol
        placeholder.fill(placeholderTextColor);
        placeholder.textSize(min(w, h) / 2);
        placeholder.textAlign(CENTER, CENTER);
        placeholder.text("?", w/2, h/2);
        
        placeholder.endDraw();
        return placeholder;
    }

    // Track loading progress
    volatile float loadingProgress = 0;
    volatile boolean isLoading = false;
    
    class LoadRequest {
        String id;
        String path;
        int targetWidth, targetHeight;
        
        LoadRequest(String id, String path, int w, int h) {
            this.id = id;
            this.path = path;
            this.targetWidth = w;
            this.targetHeight = h;
        }
    }
    
    PGraphics convertImageToGraphics(PImage image, int imageWidth, int imageHeight) {
      int startMillis = millis();
      println("Converting image " + image + " to graphics...");
      PGraphics buffer = createGraphics(imageWidth, imageHeight);
      buffer.beginDraw();
      buffer.image(image, 0, 0, imageWidth, imageHeight);
      buffer.endDraw();
      println("Converted - " + (millis()-startMillis) + " ms elapsed.");
      return buffer;
    }
    
    void addImage(String id, String path, int w, int h) {
      if (images.get(id) == null) {
        queue.add(new LoadRequest(id, path, w, h));
        totalAssets++;
      }
    }
    
    // Start loading in background
    void startLoading() {
        isLoading = true;
        loadedAssets = 0;
        loadingProgress = 0;
        
        Thread imageLoader = new Thread(() -> {
            for (LoadRequest req : queue) {
                // Load the asset
                PImage img = loadImage(req.path);
                if (img == null) {
                      // File doesn't exist - use placeholder
                      println("Warning: Image not found: " + req.path + " - Using placeholder");
                      PGraphics placeholder = createPlaceholder(req.targetWidth, req.targetHeight);
                      images.put(req.id, placeholder);
                } else {
                      // File exists - convert normally
                      PGraphics pg = convertImageToGraphics(img, req.targetWidth, req.targetHeight);
                      images.put(req.id, pg);
                }
                
                // Update progress
                loadedAssets++;
                loadingProgress = (float)loadedAssets / totalAssets;
            }
            
            isLoading = false;
        });
        imageLoader.start();
    }

    PGraphics getImage(String id) {
        if (images.get(id) != null) { return images.get(id); };
        return createPlaceholder(100, 100);
    }

    float getProgress() {
        return loadingProgress;
    }
    
    boolean isComplete() {
        return !isLoading && loadedAssets == totalAssets;
    }
}

class SaveManager {
    int currentMaxID = 0;
    int currentMaxSaveID = 1;
    String savePath = "saves";
    String defaultSaveName = "gameSave";

    // Ensure saves directory exists
    SaveManager() {
        File savesDir = new File(getSavePath(), getLastFolderName(savePath));
        if (!savesDir.exists()) {
            savesDir.mkdir();
            println("Made /saves directory");
        }
    }
    
    String getLastFolderName(String path) {
        if (path == null || path.isEmpty()) {
            return "";
        }
        
        // Remove trailing separator if present
        String cleanPath = path.endsWith(File.separator) ? 
                        path.substring(0, path.length() - 1) : path;
        
        int lastSeparator = cleanPath.lastIndexOf(File.separator);
        if (lastSeparator == -1) {
            return cleanPath; // No separator, return the whole string
        }
        
        return cleanPath.substring(lastSeparator + 1);
    }

    String getSavePath() {
        return sketchPath() + "/" + getLastFolderName(savePath);
    }

    // Assign sequential IDs to objects as they're created
    int getNextID() {
        currentMaxID++;
        return currentMaxID;
    }
    
    void saveGame(String filename) {
        JSONObject saveData = new JSONObject();

        // Save metadata
        saveData.setLong("timestamp", System.currentTimeMillis());
        saveData.setString("saveDate", LocalDateTime.now().toString());
        saveData.setInt("currentMaxID", currentMaxID);
        saveData.setInt("currentScene", gameManager.window.scene);
        saveData.setInt("saveID", currentMaxSaveID);
        
        currentMaxSaveID++;

        // ===== SAVE CONSTANTS =====
        JSONObject constantsData = new JSONObject();
        
        // Physics constants
        JSONObject physicsData = new JSONObject();
        physicsData.setFloat("GRAVITY", Constants.Physics.GRAVITY);
        physicsData.setFloat("MAX_VELOCITY", Constants.Physics.MAX_VELOCITY);
        physicsData.setFloat("CEILING_HEIGHT", Constants.Physics.CEILING_HEIGHT);
        physicsData.setFloat("LEFT_BOUNDARY", Constants.Physics.LEFT_BOUNDARY);
        physicsData.setFloat("RIGHT_BOUNDARY", Constants.Physics.RIGHT_BOUNDARY);
        constantsData.setJSONObject("Physics", physicsData);
        
        // Framework info (read-only, saved for reference)
        JSONObject frameworkData = new JSONObject();
        frameworkData.setString("NAME", Constants.Framework.NAME);
        frameworkData.setString("VERSION", Constants.Framework.FRAMEWORK_VERSION);
        frameworkData.setBoolean("BETA", Constants.Framework.BETA);
        constantsData.setJSONObject("Framework", frameworkData);
        
        saveData.setJSONObject("constants", constantsData);

        // Save ALL objects (including humans!)
        JSONArray objectsArray = new JSONArray();
        
        // Add all objects from objects list
        for (Thing obj : gameManager.objects) {
            addThingToArray(obj, objectsArray);
        }
        
        // ALSO ADD ALL HUMANS (if not already in objects)
        for (Human human : gameManager.mainHumans) {
            if (!gameManager.objects.contains(human)) {
                addThingToArray(human, objectsArray);
            }
        }
        
        saveData.setJSONArray("objects", objectsArray);
        
        // Save humans list (just IDs for mainHumans tracking)
        JSONArray humansArray = new JSONArray();
        for (Human human : gameManager.mainHumans) {
            humansArray.append(human.id);
        }
        saveData.setJSONArray("mainHumans", humansArray);
        
        // Save tracked human
        if (gameManager.trackedHuman != null) {
            saveData.setInt("trackedHumanID", gameManager.trackedHuman.id);
        }
        
        // Write to file
        saveJSONObject(saveData, getSavePath() + filename + ".json");
        println("Game saved to " + getSavePath() + filename + ".json");
    }
    
    void addThingToArray(Thing thing, JSONArray array) {
        JSONObject objData = new JSONObject();
        objData.setString("class", thing.getClass().getName());
        
        HashMap<String, Object> saveMap = thing.save();
        JSONObject dataJSON = hashMapToJSON(saveMap);
        objData.setJSONObject("data", dataJSON);
        
        array.append(objData);
    }
    
    void saveGame() {
      this.saveGame(this.defaultSaveName);
    }
    
    // Convert HashMap to JSONObject recursively
    JSONObject hashMapToJSON(HashMap<String, Object> map) {
        JSONObject json = new JSONObject();
        
        for (Map.Entry<String, Object> entry : map.entrySet()) {
            String key = entry.getKey();
            Object value = entry.getValue();
            
            if (value instanceof Integer) {
                json.setInt(key, (Integer) value);
            } else if (value instanceof Float) {
                json.setFloat(key, (Float) value);
            } else if (value instanceof Boolean) {
                json.setBoolean(key, (Boolean) value);
            } else if (value instanceof String) {
                json.setString(key, (String) value);
            } else if (value instanceof HashMap) {
                // Recursively convert nested HashMaps
                json.setJSONObject(key, hashMapToJSON((HashMap<String, Object>) value));
            } else if (value instanceof ArrayList) {
                JSONArray array = new JSONArray();
                ArrayList<?> list = (ArrayList<?>) value;
                for (Object item : list) {
                    if (item instanceof Integer) {
                        array.append((Integer) item);
                    } else if (item instanceof Float) {
                        array.append((Float) item);
                    } else if (item instanceof String) {
                        array.append((String) item);
                    } else if (item instanceof HashMap) {
                        array.append(hashMapToJSON((HashMap<String, Object>) item));
                    }
                }
                json.setJSONArray(key, array);
            }
        }
        
        return json;
    }
    
    void loadGame(String filename) {
        String fullPath = getSavePath() + filename + ".json";
        File file = new File(fullPath);
        
        // Check if file exists
        if (!file.exists()) {
            println("   ERROR: Save file not found: " + fullPath);
            return;
        }
        
        // File exists, proceed with loading
        JSONObject saveData = loadJSONObject(fullPath);
        if (saveData == null) {
            println("   ERROR: Could not parse save file: " + fullPath);
            return;
        }
 
        // Load metadata
        currentMaxID = saveData.getInt("currentMaxID");
        currentMaxSaveID = saveData.getInt("saveID");
        currentMaxSaveID++; 
        int savedScene = saveData.getInt("currentScene");
        
        // ===== LOAD CONSTANTS =====
        if (saveData.hasKey("constants")) {
            JSONObject constantsData = saveData.getJSONObject("constants");
            
            // Load physics constants
            if (constantsData.hasKey("Physics")) {
                JSONObject physicsData = constantsData.getJSONObject("Physics");
                
                if (physicsData.hasKey("GRAVITY")) 
                    Constants.Physics.GRAVITY = physicsData.getFloat("GRAVITY");
                if (physicsData.hasKey("MAX_VELOCITY")) 
                    Constants.Physics.MAX_VELOCITY = physicsData.getFloat("MAX_VELOCITY");
                if (physicsData.hasKey("CEILING_HEIGHT")) 
                    Constants.Physics.CEILING_HEIGHT = physicsData.getFloat("CEILING_HEIGHT");
                if (physicsData.hasKey("LEFT_BOUNDARY")) 
                    Constants.Physics.LEFT_BOUNDARY = physicsData.getFloat("LEFT_BOUNDARY");
                if (physicsData.hasKey("RIGHT_BOUNDARY")) 
                    Constants.Physics.RIGHT_BOUNDARY = physicsData.getFloat("RIGHT_BOUNDARY");
                    
                println("   Loaded physics constants.");
            }
            if (constantsData.hasKey("Framework")) {
                JSONObject frameworkData = constantsData.getJSONObject("Framework");
                if (frameworkData.hasKey("FRAMEWORK_VERSION")) {
                    String version = frameworkData.getString("FRAMEWORK_VERSION");
                    if (!version.equals(Constants.Framework.FRAMEWORK_VERSION)) {
                        println("   WARNING: Save file's framework version is " + version + 
                                ", but current version is " + Constants.Framework.FRAMEWORK_VERSION + ". This may cause compatibility issues.");
                    }
                }
            }
        }

        // Create a map of existing objects by ID
        HashMap<Integer, Thing> existingThings = new HashMap<Integer, Thing>();
        for (Thing obj : gameManager.objects) {
            existingThings.put(obj.id, obj);
        }
        for (Human human : gameManager.mainHumans) {
            existingThings.put(human.id, human);
        }
        
        // Load objects data and update existing instances
        JSONArray objectsArray = saveData.getJSONArray("objects");
        JSONArray humansArray = new JSONArray();
                    
        println("   Loading objects...");
        for (int i = 0; i < objectsArray.size(); i++) {
            JSONObject objData = objectsArray.getJSONObject(i);
            JSONObject dataJSON = objData.getJSONObject("data");
            
            // Get ID from the data JSON
            int objId = dataJSON.getInt("id");
            
            // Find the existing object with this ID
            Thing existingThing = existingThings.get(objId);
            if (existingThing != null) {
                // Convert JSONObject to HashMap and load
                HashMap<String, Object> dataMap = jsonToHashMap(dataJSON);
                existingThing.load(dataMap);
            } else {
                println("   WARNING: No existing object found with ID: " + objId);
            }
        }
        
        // Load mainHumans list
        if (saveData.hasKey("mainHumans")) {
            humansArray = saveData.getJSONArray("mainHumans");
            gameManager.mainHumans.clear();
            
            println("   Loading mainHumans...");
            
            // First, find the human data from objectsArray
            HashMap<Integer, JSONObject> objectDataMap = new HashMap<Integer, JSONObject>();
            for (int i = 0; i < objectsArray.size(); i++) {
                JSONObject objData = objectsArray.getJSONObject(i);
                JSONObject dataJSON = objData.getJSONObject("data");
                int objId = dataJSON.getInt("id");
                objectDataMap.put(objId, dataJSON);
            }
            
            for (int i = 0; i < humansArray.size(); i++) {
                int humanID = humansArray.getInt(i);
                
                Thing human = existingThings.get(humanID);
                if (human == null) {
                    println("   Human not found in existingThings!");
                    continue;
                }
                
                // Load the human's data
                JSONObject humanData = objectDataMap.get(humanID);
                if (humanData != null) {
                    HashMap<String, Object> dataMap = jsonToHashMap(humanData);
                    human.load(dataMap);
                    
                    gameManager.mainHumans.add((Human) human);
                    println("   Loaded " + human.getClass().getSimpleName() + " (ID " + humanID + ")");
                } else {
                    println("   No save data found for human ID " + humanID);
                }
            }
        } else {
          println("   No mainHumans were found!");
        }
        
        // Load tracked human
        if (saveData.hasKey("trackedHumanID")) {
            int trackedID = saveData.getInt("trackedHumanID");
            Thing tracked = existingThings.get(trackedID);
            if (tracked instanceof Human) {
                gameManager.trackedHuman = (Human) tracked;
                println("   Tracked human set to ID: " + trackedID);
            }
        }
        
        // Set current scene
        gameManager.window.scene = savedScene;
        
        println("   Updated " + objectsArray.size() + " objects");
        println("   Updated " + humansArray.size() + " humans");
        println("   Game loaded from " + getSavePath() + filename + ".json!");
        gameManager.messageBox.showEvent("Game loaded from " + filename + ".json!");
    }
    
    void loadGame() {
      this.loadGame(this.defaultSaveName);
    }
    
    // Convert JSONObject to HashMap recursively
    HashMap<String, Object> jsonToHashMap(JSONObject json) {
        HashMap<String, Object> map = new HashMap<String, Object>();
        
        // Get all keys
        for (Object keyObj : json.keys()) {
            String key = (String) keyObj;
            
            // Determine the type and extract value
            if (json.isNull(key)) continue;
            
            if (json.get(key) instanceof Integer) {
                map.put(key, json.getInt(key));
            } else if (json.get(key) instanceof Float) {
                map.put(key, json.getFloat(key));
            } else if (json.get(key) instanceof Double) {
                map.put(key, (float) json.getDouble(key));
            } else if (json.get(key) instanceof Boolean) {
                map.put(key, json.getBoolean(key));
            } else if (json.get(key) instanceof String) {
                map.put(key, json.getString(key));
            } else if (json.get(key) instanceof JSONObject) {
                map.put(key, jsonToHashMap(json.getJSONObject(key)));
            } else if (json.get(key) instanceof JSONArray) {
                JSONArray array = json.getJSONArray(key);
                ArrayList<Object> list = new ArrayList<Object>();
                
                for (int i = 0; i < array.size(); i++) {
                    if (array.isNull(i)) continue;
                    
                    if (array.get(i) instanceof Integer) {
                        list.add(array.getInt(i));
                    } else if (array.get(i) instanceof Float) {
                        list.add(array.getFloat(i));
                    } else if (array.get(i) instanceof Boolean) {
                        list.add(array.getBoolean(i));
                    } else if (array.get(i) instanceof String) {
                        list.add(array.getString(i));
                    } else if (array.get(i) instanceof JSONObject) {
                        list.add(jsonToHashMap(array.getJSONObject(i)));
                    }
                }
                map.put(key, list);
            }
        }
        
        return map;
    }
}

public static class Constants { 
    public static final class Framework {
        public static final String NAME = "Person Framework"; 
        public static final String FRAMEWORK_VERSION = "4.1.2";
        public static final boolean BETA = false;
    }

    // Physics constants - not final, as game may need changing gravity, groundHeight, grabRange, etc.
    public static class Physics {
        public static float CEILING_HEIGHT = 0.2f;
        public static float LEFT_BOUNDARY = 0.08f;
        public static float RIGHT_BOUNDARY = 0.95f;
        public static float GRAVITY = 6.5f;
        public static float MAX_VELOCITY = 40f; 
    }
}

void setTrackedHuman(Human human) {
    gameManager.trackedHuman = human;
}

