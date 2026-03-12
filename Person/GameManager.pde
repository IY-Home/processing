import java.util.*;

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
    MessageBox messageBox;
    
    
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
        
        // Initialize game - pass window directly
        createScenes(window);
        createHumans(mainHumans);
        createObjects(objects);
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

public static class Constants { 
    public static final class Framework {
        public static final String NAME = "Person Framework"; 
        public static final String FRAMEWORK_VERSION = "3.7.0";
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