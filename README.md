# 'Person' - Processing Game Framework v4

## **Overview**
A modular, object-oriented 2D game framework built in Processing. This project provides a solid foundation for creating interactive games with physics, inventory systems, UI elements, character interactions, and full game state persistence with save functionality.

## **Features**

### **Core Systems**
- **Game Manager** - Central manager of objects and humans, window and scenes, and constants
- **Physics Engine** - Gravity, collision detection, velocity, and friction
- **Scene Management** - Multiple scenes with day/night transitions
- **Input System** - Customizable input boxes for text/password entry
- **Inventory & Economy** - Money system, purchasable items, hunger mechanics
- **Character Controller** - Human character with movement, jumping, grabbing
- **Image Manager** - Asynchronous background loading of images with progress tracking
- **Save/Load System** - Full game state persistence with JSON serialization (v4.1.0+)

### **Interactive Objects**
- **CashBags** - Password-protected money containers with InputBox integration
- **Lunchboxes** - Edible food items with price and hunger restoration. It is also the base class for any food items.
- **Furniture** - Chairs, cupboards, pantries with storage capabilities
- **Doors** - Scene transition portals
- **Drone** - Flyable drone with battery management
- **Clothing** - Swappable shirts with color customization

### **UI Elements**
- **Hunger Bar** - Visual hunger indicator with color coding
- **Money Display** - Real-time currency tracking
- **InputBox Class** - Reusable text input with password masking
- **Custom Cursor** - Blue circular cursor design
- **Loading Screen** - Animated splash screen with progress bar and rotating tips

## **Project Structure (in `/Source`)**

### **Core framework**

#### **Main.pde**
- Entry point with `setup()` and `draw()` functions
- Creates GameManager instance via user-defined `createGameManager()`
- Sets window title and starts the game

#### **KeyHandlers.pde**
- Key input handling and event system
- `KeyManager` class tracks key states

#### **GameManager.pde**
- **`GameManager`** - Central class containing:
  - Global variables and physics constants
  - Collections of all objects, humans, and input boxes
  - Main update loop
  - References to Window, KeyManager, ImageManager, and SaveManager systems
- **`Window`** - Display/background and scene management
- **`KeyManager`** - Key event handling
- **`ImageManager`** - Image storage and asynchronous image loading and caching
- **`SaveManager`** - Handles JSON serialization, ID assignment, and save/load operations
- **`CircularArrayList`** - Extended ArrayList with looping and type-safe getters

#### **BaseClasses.pde**
- **`Thing`** - Abstract base class for all game objects (implements `Saveable`)
- **`Human`** - Basic human with drawing and movement logic
- **`Interactable`** - Interface for interactive objects
- **`KeyEvents`** - Interface for objects that respond to keyboard input
- **`Saveable`** - Interface for objects that can be saved/loaded
- **`InputBox`** - Text input UI with password support and callbacks

### **Examples**

#### **LoadingManager.pde**
- Example of extending GameManager to add custom features
- `GameManagerWithLoading` adds splash screen with progress bar
- `LoadingManager` handles staged loading with background image loading
- `SplashScreen` animated loading display with tips

#### **Classes (GameHuman.pde and ObjectClasses.pde)**
- **`GameHuman`** - Game player character with hunger/money systems and background updates
- **`ImageHuman`** - Human that uses an image from ImageManager for appearance
- **`Ball` and `BouncyBall`** - Physics objects with collision and throw mechanics
- **`Shirt`** - Wearable clothing item with color swapping
- **`Chair`** - Sit-able furniture with object stacking
- **`Door`** - Scene transition object
- **`Cupboard`/`PreFilledCupboard`** - Storage containers with item management
- **`Drone`** - Controllable flying device with battery and recharging
- **`Lunchbox`** - Consumable food items with price and hunger restoration
- **`CashBag`** - Password-protected money bags with cooldown system

#### **Debug.pde**
- **`Debug`** - Debugging HUD with tracked human info

## **Example Gameplay Mechanics**

### **Character Controls**
- **Arrow Keys/Mouse** - Move left/right
- **Up Arrow/Middle Click** - Jump
- **Down Arrow/Space/Right Click** - Grab/release objects
- **SHIFT Key** - Special interactions (eat food, stand on chair, throw balls, etc.)
- **S Key** - Save game (creates `saves/gameSave.json`)

### **Object Interactions**

1. **Eat Food**: Grab a lunchbox, press SHIFT
2. **Unlock CashBag**: Interact with bag, enter password in InputBox
3. **Change Shirt**: Grab shirt, press SHIFT to swap colors
4. **Fly Drone**: Use WASD keys when drone is selected, press R to recharge
5. **Enter Door**: Grab door to change scenes
6. **Open Pantry**: Interact with PreFilledCupboard to access stored food
7. **Stack Objects**: Drop items near chairs to place them
8. **Throw Balls**: Grab a ball and press SHIFT to throw

### **Hunger System**
- Hunger increases over time and with movement
- Eat lunchboxes to reduce hunger (costs money)
- Game over when hunger reaches 100%
- Background updates keep hunger progressing even when character is off-screen

### **Money System**
- Starting money: $200
- Earn money by unlocking CashBags with correct passwords
- Spend money on food to reduce hunger

### **Password Puzzles**
- Three CashBags with different passwords:
  - $50 bag: "1234" (First 4 numbers!)
  - $100 bag: "Hello" (A common English greeting!)
  - $200 bag: "P@55$ec6re" (You shall never guess it.)

## **Technical Highlights**

### **Object-Oriented Design**
- Clean inheritance hierarchy (`Thing` -> specific objects)
- Interface-based interactions (`Interactable`, `KeyEvents`, `Saveable`)
- Encapsulated game state management with GameManager
- Composition over inheritance where appropriate

### **Save/Load System (v4.1.0+)**
- **Automatic ID assignment**: Every object gets a sequential ID based on creation order in `GameInit.pde`
- **Saveable interface**: Objects implement `save()` and `load()` methods to serialize their state
- **Two-pass loading**: First loads all object data, then resolves cross-references (grabbed objects, chair occupancy, cupboard contents)
- **JSON serialization**: Human-readable save files in the `saves/` folder
- **Reference resolution**: Objects store IDs of referenced objects (e.g., `grabObjID`, `restedObjID`) for proper relationship restoration
- **Transient state handling**: Temporary variables like grab cooldowns are reset on load
- **Press 'S' to save** - Creates `gameSave.json` in the `saves/` directory
- **Automatic loading** - Game state restores from save file at startup if one exists

### **Input Box System**
- Reusable `InputBox` class with password masking
- Callback-based submission/cancellation using Runnable interfaces
- Global input box management to prevent conflicts
- Visual feedback with blinking cursor and text clipping

### **Physics Implementation**
- Velocity/acceleration-based movement with configurable gravity
- Elastic collisions and friction per object
- Screen boundary constraints with configurable bounds
- Background updates for persistent objects

### **Scene Management**
- Mix of colors and images for backgrounds
- Seamless transitions via doors
- Object visibility based on current scene
- Ground rendering toggle per scene
- **Terrain system**: Ground keyframes with interpolation for hills, stairs, and holes

### **Image Management System**
- Central image storage
- Asynchronous loading in background thread
- Thread-safe progress tracking with volatile variables
- Automatic image conversion to PGraphics
- Centralized resource caching to prevent duplicate loads
- Images are queued during object creation
- Background loading with real progress tracking
- Automatic placeholder generation for missing images
- Shared image resources across multiple instances

### **Customization**
- Add new scenes by extending color/image array
- Create new object types by extending `Thing`
- Modify constants and physics properties
- Add more interactive items with `Interactable` interface
- Create your own game mechanics by extending existing classes
- Use ImageManager for efficient asset loading
- **Extend save/load** by overriding `save()` and `load()` in custom objects

## **Code Philosophy**

- **Modular**: Each class handles its own logic in separate files
- **Extensible**: Easy to add new features by extending existing classes
- **Reusable**: Components like InputBox, ImageManager, and SaveManager can be used anywhere
- **Clean**: Separation of concerns between files and classes
- **Non-invasive**: Core files never need modification - extend instead!

## **Design Notes**

- **Color Scheme**: Day/night cycles with distinct palettes
- **UI**: Minimalist with contextual information
- **Feedback**: Visual and console feedback for all actions
- **Loading**: Smooth animated loading with real progress from ImageManager
- **Persistence**: Complete game state restoration including object references

---

## Getting Started and GameInit.pde

- To start building your game with this framework, you only need to edit GameInit.pde and create your own files to contain your classes.

1. Import all files into Processing (download their IDE on [their website](https://processing.org)), either by cloning this repository or downloading the individual files (in `/Source`): `BaseClasses.pde` (base classes), `GameHuman.pde` (Human extensions), `ObjectClasses.pde` (sample object classes), `GameManager.pde` (core systems), `KeyHandlers.pde` (input), `LoadingManager.pde` (optional loading screen), `Main.pde` (main setup/draw), and `GameInit.pde` (your game configuration).
2. You can edit, rename, or remove the example GameInit.pde and ObjectClasses.pde files. (You are recommended to use them as templates.)
3. In your **`GameInit.pde`,** implement the following functions:

### **`GameManager createGameManager()`**

Creates and returns the main GameManager instance. Called at the very start of the program to define the global gameManager instance.

You return a GameManager object here (default is `return new GameManager("myName", "myVersion")`). This is useful if you extend GameManager to create your own custom manager (e.g. GameManagerWithLoading).

You can configure the GameManager before returning it:
- Change the program name and version
- Modify physics constants (GRAVITY, MAX_VELOCITY, etc.)
- Adjust gameplay settings (GRAB_RANGE, GROUND_HEIGHT, etc.)
- Enable/disable save system (`gm.useSaveSystem = false`)

You may also put any code that needs to execute at program startup here:
- Initialize libraries (Minim, Network, etc.)
- Load configuration files
- Parse command line arguments
- Setup logging

Returns: GameManager - Any class that extends GameManager

Example:
```java
GameManager createGameManager() {
    GameManager gm = new GameManagerWithLoading("My Game", "2.0");
    gm.startupMessage = "Welcome to my game!";
    return gm;
}
```

### **`Boolean initLoadingScreen(LoadingManager loader)`**

Configures the optional loading/splash screen (for if you used the provided GameManagerWithLoading). Called during GameManager initialization.

To disable the splash screen entirely, just `return false`.

You can customize the loading screen by modifying loader properties:
- loadingMessages: String[] of messages to display during each loading stage
- loadingTips: String[] of tips that rotate during loading
- backgroundColor1/backgroundColor2: Colors for animated background (lerpColor)
- progressBarColor: Color of the progress bar
- framesPerStage: How many frames each loading stage takes

The loading screen automatically integrates with ImageManager to show real progress during image loading.

Parameters:
    loader - LoadingManager instance to configure

Returns: boolean - true to enable loading screen, false to disable

Example:
```java
Boolean initLoadingScreen(LoadingManager loader) {
    String[] tips = {
        "Press DOWN to grab objects",
        "SHIFT interacts with held objects",
        "Find cash bags with hidden passwords!",
        "Press S to save your game"
    };
    loader.loadingTips = tips;
    loader.progressBarColor = color(255, 200, 100);
    return true;
}
```

### **`void createScenes(Window window)`**

Sets up all game scenes, backgrounds, and window properties.

You must define:
- The scenes themselves (colors or images)
- Whether each scene has ground
- The starting scene
- The trash scene (where deleted objects go)
- Cursor color

window.addScenes() takes two parallel arrays:
- First array: Object[] containing colors (Integer) or image paths (String) - both can coexist
- Second array: Boolean[] indicating whether each scene has ground

You can freely mix solid colors and images. For images:
- Store them in the 'data' folder
- Use just the filename (e.g., "beach.png")
- ImageManager automatically loads them in the background

You can also change the ground height across the scene like a terrain. Use `window.addGroundKeyframe(int scene, float xPosition, float height)`.
- int scene sets which scene to add the keyframe.
- float xPosition sets the x position of the keyframe (vertex).
- float height sets the height of that vertex, in a normalized value between 0 and 1, multipled by the screen height (height).
- If you want to have a uniform ground height, set window.defaultGroundHeight.

Additional window properties you can set:
- groundColor: Color of the ground
- frameSpeed: Game speed (1.0 = 60fps, 0.5 = 30fps)
- cursorSize: Size of the custom cursor
- scenes.setLoop(true/false): Whether scene indices wrap around
- scenes.setDefaultReturnValue(): Fallback color for invalid scenes

Parameters:
    window - Window instance to configure

Example:
```java
void createScenes(Window window) {
    window.addScenes(
        new Object[]{color(90,210,255), "beach.png", color(18,19,65)},
        new Boolean[]{true, false, true}
    );
    
    window.addGroundKeyframe(2, 0, 0.8);    // Start at 80%
    window.addGroundKeyframe(2, 200, 0.8);  // Still 80%, slope starts
    window.addGroundKeyframe(2, 750, 0.5);  // Top of the hill
    window.addGroundKeyframe(2, 1000, 0.8); // Back to 80% at end of the hill
    
    window.scene = 0;
    window.trashScene = 999;
    window.cursorColor = color(0, 120, 255);
    window.scenes.setLoop(true);
}
```

### **`void createHumans(ArrayList<Human> humans)`**

Creates all player characters and NPCs (if you have them) in the game.

You create Human objects and add them to the ArrayList passed in. This ArrayList becomes the mainHumans list in the GameManager that the game updates (live()).

Base Human constructor:
    `Human(String name, color hairColor, color shirtColor, color pantColor, color shoeColor, float posX, int sceneIn)`

Extended humans available (examples):
- GameHuman: Adds hunger/money systems and background updates
- ImageHuman: Uses an image from ImageManager for appearance

To make the game track the scene of the human, use `setTrackedHuman(Human human)`.

Parameters:
    humans - ArrayList to add Human objects to

Example:
```java
void createHumans(ArrayList<Human> humans) {
    GameHuman player = new GameHuman(
        "Isaac", "Tan", "boy", 10,
        color(0), color(0,0,255), color(50), color(0),
        2.5, 200.0, width * 0.68, 0
    );
    humans.add(player);
    setTrackedHuman(player);
    
    ImageHuman npc = new ImageHuman("Joe", "person.png", width * 0.3, 0);
    npc.hasControls = false;
    humans.add(npc);
}
```

### **`void createObjects(ArrayList<Thing> things)`**

Creates all interactive objects, furniture, items, and physics objects.

You create Thing objects and add them to the ArrayList passed in. This becomes the global objects list that the game updates, displays, and checks for collisions.

**Important for save/load**: Objects receive sequential IDs based on the order they're added here. The first object gets ID 1, second gets ID 2, etc. This ensures consistent ID assignment across save/load cycles.

Objects that use images (BouncyBall, ImageHuman, etc.) automatically queue them with ImageManager when constructed. No additional steps needed.

Parameters:
    things - ArrayList to add Thing objects to

Example:
```java
void createObjects(ArrayList<Thing> things) {
    color wood = color(200,100,0);
    
    things.add(new Door(width*0.9, width*0.1, wood, 0, 1));  // ID: 1
    things.add(new Chair(wood, 700, 0));                      // ID: 2
    things.add(new BouncyBall("football.png", 70, 200, 0.85, 0)); // ID: 3
    things.add(new CashBag(color(50,200,50), 400, 0, 50, "1234", "Hint")); // ID: 4
    things.add(new Lunchbox("Pizza", color(255,100,50), 300, 0, 15, 25)); // ID: 5
}
```

### **`void loop()`**

Executes every frame (60 times per second at default speed).

Put any code here that needs to run continuously during the game:
- Custom game logic
- Spawning new objects
- Checking win/loss conditions
- Debug output

Example:
```java
void loop() {
    if (frameCount % 300 == 0) {  // Every 5 seconds
        println("Time passes...");
    }
    myObject.customUpdate();
}
```

---

That's the end of your GameInit.pde. But what if you want to extend your game by making your own objects?

## **Creating Custom Object Classes**

Create your own .pde file and extend existing classes. The framework supports full save/load functionality for custom objects - you just need to override the `save()` and `load()` methods to include your custom properties.

### **Basic Custom Object Template**

```java
class MyNewObject extends Thing implements Interactable, KeyEvents {
    // Your custom properties
    int myCustomProperty;
    int myDefaultProperty = 0;
    Thing targetObject = null;
    
    // Constructor
    MyNewObject(float posX, int sceneIn, int customProperty) {
        super(); // Call Thing constructor
        this.initialize(posX, height * 0.5); // Initialize with position
        // this.initialize(); // Or initialize with default position
        this.sceneIn = sceneIn;
        this.grabbable = true;
        this.myCustomProperty = customProperty;
        
        // Optional: Configure collision detection
        this.checkTouchRadius = 70; // Enable onTouch() at this distance
        this.checkTouchY = true;     // Use full 2D distance check
        this.checkTouchWide = false; // If true, enables distance checking of any radius, and if false, maximum distance is 200px.
        
        // Optional: Rendering layers
        this.drawInBackground = true;  // Draw behind other objects
        this.drawInForeground = false; // Draw in front
        this.drawBehindHumans = false; // Draw relative to humans
        
        // Optional: Background updates
        this.updateInBackground = true; // Update even when not in scene
    }
    
    // Required display method
    void display() {
        // Your drawing code here
    }
    
    // Optional: Collision detection
    void onTouch(Thing other, float distance) {
    }
    
    // ===== SAVE/LOAD METHODS =====
    // Override these to persist your custom properties
    
    @Override
    HashMap<String, Object> save() {
        // ALWAYS call super.save() first to save base class properties
        // (id, position, velocity, flags, etc.)
        HashMap<String, Object> data = super.save();
        
        // Add your custom properties to the HashMap
        data.put("myCustomProperty", this.myCustomProperty);
        data.put("myDefaultProperty", this.myDefaultProperty);
        
        // Save references to other objects by their ID
        // (instead of saving the entire object)
        // if (this.targetObject != null) {
        //     data.put("targetObjectID", this.targetObject.id);
        // }
        
        return data;
    }
    
    @Override
    void load(HashMap<String, Object> data) {
        // ALWAYS call super.load() first to restore base class properties
        super.load(data);
        
        // Restore your custom properties
        if (data.containsKey("myCustomProperty")) {
            this.myCustomProperty = ((Number) data.get("myCustomProperty")).intValue();
        }
        if (data.containsKey("myDefaultProperty")) {
            this.myDefaultProperty = (Number) data.get("myDefaultProperty");
        }

        if (data.containsKey("targetObjectID")) {
            this.loadObj(gameManager.objects, (int) data.get("grabObjID"));
        }
    }
    
    void loadObj(ArrayList<Thing> objects, int objId) {
        if (objId > 0) {
            for (Thing obj : objects) {
                if (obj instanceof Saveable && obj.id == objId) {
                    this.targetObj = obj;
                    break;
                }
            }
        }
    }
    
    // ===== INTERACTABLE INTERFACE METHODS =====
    // (optional - only if you want the object to be interactive)
    
    @Override
    void onGrab(Human human) {
        // Called when human grabs this object
        gameManager.messageBox.showEvent("Object grabbed!");
    }
    
    @Override
    void onInteract(Human human) {
        // Called when human presses SHIFT while holding this object
        gameManager.messageBox.showEvent("Object interacted with!");
    }
    
    @Override
    boolean isGrabbable() {
        // Can return dynamic state (e.g., not grabbable when empty)
        return this.grabbable && !this.held && ammo > 0;
    }
    
    @Override
    void onRelease(Human human) {
        // Called when human releases the object
    }
    
    // ===== KEYEVENTS INTERFACE METHODS =====
    // (optional - only if object responds to keyboard)
    
    @Override
    void keyDown(char key, int keyCode) {
        if (key == 'F') {
            // Special action when F is pressed
        }
    }
    
    @Override
    void keyUp(char key, int keyCode) {
        // Handle key release
    }
}
```

### **Important Save/Load Principles**

1. **Always call `super.save()` and `super.load()` first** - This ensures base class properties (position, velocity, flags, ID) are properly handled.

2. **Save references as IDs, not objects** - When your object references another object (like a target or owner), save its ID:
   ```java
   if (targetObject != null) {
       data.put("targetID", targetObject.id);
   }
   ```
   
3. **Transient variables** - Don't save temporary state like timers or cooldowns. Reset them in `load()` if needed:
   ```java
   @Override
   void load(HashMap<String, Object> data) {
       super.load(data);
       // Reset transient state
       this.lastFiredTime = 0;
       this.cooldownActive = false;
   }
   ```

4. **ID assignment is automatic** - Objects receive sequential IDs based on creation order in `createObjects()`. No manual ID assignment needed!

---

## **ImageManager Integration**

The ImageManager handles all image loading automatically:

- **Automatic queuing**: Objects queue images in their constructors via `addImage()`
- **Background loading**: `startLoading()` begins the asynchronous load
- **Progress tracking**: `getProgress()` returns 0.0-1.0 for loading screens
- **Automatic placeholders**: Missing images show magenta/cyan checkerboard with "?"
- **Thread-safe**: Volatile variables ensure safe cross-thread communication

Images are loaded once and shared across all instances using the same path.

The ImageManager works automatically in the background:
- Objects queue images via addImage() in their constructors
- Images load asynchronously during the loading screen
- getImage() returns the loaded PGraphics or a placeholder if not ready
- Progress is tracked and displayed on the loading screen

You don't need to interact with ImageManager directly unless creating custom image-based objects.
To add an image to ImageManager, the default is to load the image in the constructor of the object class (see the example `BouncyBall` class) by executing `gameManager.imageManager.addImage("Unique_ID_for_Image_Usually_Same_As_Filename", "filename.png", width, height)`, and to get the image in `PGraphics` form by calling `gameManager.imageManager.getImage("Unique_ID_for_Image")`. If you need to load images at game time, they aren't automatically loaded after an `addImage()` call. You have to call `gameManager.imageManager.startLoading()` to load all new images.

**Note: do not call `startLoading()` after every `addImage`! Instead, add all images to the ImageManager queue first, then call `startLoading()` to load all of them at once.**

---

## **Save/Load System (v4.1.0+)**

The framework includes a comprehensive save/load system that persists the entire game state to JSON files.

### **How It Works**
- **Automatic ID assignment**: Every object gets a unique sequential ID based on creation order in `GameInit.pde`
- **Saveable interface**: Objects implement `save()` and `load()` methods to serialize their state
- **Two-pass loading**: First loads all object data, then resolves cross-references (grabbed objects, chair occupancy, cupboard contents)
- **JSON serialization**: Human-readable save files in the `saves/` folder
- **Transient state handling**: Temporary variables like grab cooldowns are reset on load

### **Built-in Save/Load**
- Press **'S'** to save the game (creates `gameSave.json` in the `saves/` folder)
- Loading happens automatically at startup (if a save file exists)
- All objects and humans restore their exact state including:
  - Positions and velocities
  - Physics properties (elasticity, friction)
  - Game state (hunger, money, unlocked status)
  - Object references (grabbed objects, chair occupancy)
  - Container contents (cupboard shelves)
  - Scene membership and visibility flags

### **The Saveable Interface**
```java
interface Saveable {
    HashMap<String, Object> save();
    void load(HashMap<String, Object> data);
}
```

Any class implementing `Saveable` can be persisted. The `Thing` base class already implements this, so all your objects inherit save/load functionality.

### **ID Assignment**
IDs are assigned sequentially based on creation order:
- First object in `createObjects()` gets ID 1
- Second object gets ID 2, etc.
- Humans in `createHumans()` get IDs after all objects

This ensures consistent ID assignment across save/load cycles without any manual configuration.

---

## **Examples Provided**

1. **GameInit.pde** - Complete game setup with scenes, characters, and objects
2. **ObjectClasses.pde** - Various object types demonstrating different features including save/load
3. **GameHuman.pde** - Extended human with hunger/money and background updates
4. **LoadingManager.pde** - Custom GameManager extension with loading screen

Need a specific example?
- Simple physics object: See `Ball` class
- Image-based object: See `BouncyBall` or `ImageHuman`
- Interactive furniture: See `Chair` class
- Scene transition: See `Door` class
- Password input: See `CashBag` class
- Storage system: See `PreFilledCupboard` class
- Background updates: See `GameHuman` or `Door`
- Asynchronous loading: See `ImageManager` and `LoadingManager`
- Save/load implementation: See any class extending `Thing`

