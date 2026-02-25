class GameManagerWithLoading extends GameManager {
    // Loading screen
    boolean showLoadingScreen = true;
    float loadingProgress = 0;
    String loadingMessage = "Starting...";
    long loadStartTime;
    LoadingManager loader;

    GameManagerWithLoading(String name, String version) {
        super(name, version);
        loader = new LoadingManager(this);
        showLoadingScreen = initLoadingScreen(loader);
    }
    
    void init() {        
        if (showLoadingScreen) {
           // Start the loading process
           loader.start();
        } else {     
           super.init();      
        }
        
    }
    
    void update() {
        if (showLoadingScreen && loader.isLoading()) {
            // Let loader handle everything during loading
            loader.update();
        } else {
            // Normal game update
            super.update();
        }
    }
}



class LoadingManager {
    // Loading state
    boolean isLoading = true;
    int loadingStage = 0;
    int maxStages;
    int frameCounter = 0;
    int framesPerStage = 15; // Wait between stages
    
    // Special image loading state
    boolean waitingForImages = false;
    
    // Loading content
    String[] loadingMessages;
    String[] loadingTips;
    SplashScreen splash;
    
    color backgroundColor1 = color(20, 20, 40); 
    color backgroundColor2 = color(40, 40, 80);
    color progressBarColor = color(100, 200, 255);
    
    // References to game components (injected)
    GameManager gm;
    Window window;
    ImageManager im;
    ArrayList<Thing> objects;
    ArrayList<Human> humans;
    
    LoadingManager(GameManager gameManager) {
        this.gm = gameManager;
        this.window = gameManager.window;
        this.objects = gameManager.objects;
        this.humans = gameManager.mainHumans;
        this.im = gameManager.imageManager;
        
        // Default messages
        loadingMessages = new String[] {
            "Initializing...",
            "Clearing resources...", 
            "Loading scenes...",
            "Creating characters...",
            "Placing objects...",
            "Loading images...",
            "Setting up physics...",
            "Starting game!"
        };
        
        loadingTips = new String[] {
            "You can change loading tips by changing the array loader.loadingTips!"
        };
        
        maxStages = loadingMessages.length;
    }
    
    void start() {
        splash = new SplashScreen(gm.programName, gm.version, backgroundColor1, backgroundColor2, progressBarColor);
        splash.setTips(loadingTips);
        isLoading = true;
        loadingStage = 0;
        frameCounter = 0;
        waitingForImages = false;
        println(gm.startupMessage);
        println("Loading started...");
    }
    
    void update() {
        if (!isLoading) return;
        
        frameCounter++;
        
        // SPECIAL HANDLING: Waiting for images to load in background
        if (waitingForImages) {
            updateImageLoading();
            return;
        }
        
        // NORMAL: Stage-based loading
        updateNormalLoading();
    }
    
    void updateImageLoading() {
        // Get real progress from ImageManager
        float imageProgress = im.getProgress();
        
        // Calculate where stage 5 sits in total progress (5/8 to 6/8)
        float stageStart = (float)loadingStage / maxStages;
        float stageEnd = (float)(loadingStage + 1) / maxStages;
        float stageRange = stageEnd - stageStart;
        
        // Total progress = progress through entire loading
        float totalProgress = stageStart + (imageProgress * stageRange);
        
        // Create dynamic message showing current image
        String currentImage = "unknown";
        if (im.loadedAssets < im.totalAssets && im.queue != null && im.queue.size() > 0) {
            // Get the next image to load (or currently loading)
            int nextIndex = im.loadedAssets;
            if (nextIndex < im.queue.size()) {
                currentImage = im.queue.get(nextIndex).id;
            }
        }
        
        String message = "Loading images: " + (im.loadedAssets + 1) + "/" + im.totalAssets;
        if (im.loadedAssets < im.totalAssets) {
            message += " (" + currentImage + ")";
        }
        
        // Update splash with real progress
        if (splash != null) {
            splash.update(message, totalProgress);
            splash.draw();
        }
        
        // Check if image loading is complete
        if (im.isComplete()) {
            waitingForImages = false;
            loadingStage++;  // Move to next stage
            frameCounter = 0;
            println("  ✓ All " + im.totalAssets + " images loaded (" + 
                   (int)(imageProgress * 100) + "%)");
        }
    }
    
    void updateNormalLoading() {
        // Perform actual loading work at start of each stage
        if (framesPerStage == 0 || frameCounter % framesPerStage == 1) {
            performLoadingStage(loadingStage);
        }
        
        // Calculate current progress through this stage
        float stageProgress = 0;
        if (framesPerStage > 0) {
            stageProgress = (float)(frameCounter % framesPerStage) / framesPerStage;
        }
        
        // Advance to next stage when enough frames have passed
        if (framesPerStage == 0 || frameCounter % framesPerStage == 0) {
            loadingStage++;
            
            // Check if loading is complete
            if (loadingStage >= maxStages) {
                finishLoading();
            } else {
                frameCounter = 0; // Reset counter for next stage
            }
        }
        
        // Calculate total progress across all stages
        float totalProgress = (loadingStage + stageProgress) / maxStages;

        // Get current stage message
        String message = loadingMessages[min(loadingStage, maxStages - 1)];
        
        // Update splash
        if (splash != null) {
            splash.update(message, totalProgress);
            splash.draw();
        }
        
    }
    
    void performLoadingStage(int stage) {
        switch(stage) {
            case 0: // Already initialized
                break;
                
        case 1: // Clear old state
            objects.clear();
            humans.clear();
            gm.activeInputBoxes.clear();
            window.scenes.clear();
            gm.keyManager.resetAllKeys();
            println("  ✓ Resources cleared ");
            break;
            
        case 2: // Load scenes
            createScenes(window);
            println("  ✓ Scenes loaded ");
            break;
            
        case 3: // Create humans
            createHumans(humans);
            println("  ✓ Characters created ");
            break;
            
        case 4: // Create objects
            createObjects(objects);
            println("  ✓ Objects placed ");
            break;
                
            case 5: // START loading images in background
                if (im.totalAssets > 0) {
                    im.startLoading();
                    waitingForImages = true;  // Enter special waiting mode
                    println("  → Image loading started (" + im.totalAssets + " images)");
                } else {
                    // No images to load, skip waiting
                    println("  ✓ No images to load");
                    waitingForImages = false;
                    loadingStage++; // Move to next stage immediately
                }
                break;
                
            case 6: // Final setup (only reached after images done)
                println("  ✓ Game configured");
                break;
                
            case 7: // Almost done
                println("  ✓ Finalizing");
                break;
        }
    }
    
    void finishLoading() {
        isLoading = false;
        waitingForImages = false;
        if (splash != null) {
            splash.deactivate();
        }
        println("\n✓ Game initialized! (" + (millis() - splash.startTime) + "ms)");
    }
    
    boolean isLoading() {
        return isLoading;
    }
    
    // Optional: Customize loading experience
    void setMessages(String[] messages) {
        this.loadingMessages = messages;
        this.maxStages = messages.length;
    }
    
    void setTips(String[] tips) {
        this.loadingTips = tips;
        if (splash != null) {
            splash.setTips(tips);
        }
    }
    
    void setFramesPerStage(int frames) {
        this.framesPerStage = frames;
    }
}

class SplashScreen {
    PGraphics buffer;
    boolean active = true;
    String message = "";
    float progress = 0;
    long startTime;
    String gameTitle;
    String gameVersion;
    String[] tips;
    
    color backgroundColor1;
    color backgroundColor2;
    color progressBarColor;
    
    SplashScreen(String title, String version, color bg1, color bg2, color pb) {
        this.gameTitle = title;
        this.gameVersion = version;
        this.buffer = createGraphics(width, height);
        this.startTime = millis();
        
        this.backgroundColor1 = bg1; 
        this.backgroundColor2 = bg2;
        this.progressBarColor = pb;
        
        // Default tips - can be overridden
        this.tips = new String[] {
            "Loading...",
            "Please wait...",
            "Almost there..."
        };
    }
    
    void setTips(String[] customTips) {
        this.tips = customTips;
    }
    
    void update(String msg, float prog) {
        message = msg;
        progress = prog;
    }
    
    void draw() {
        if (!active) return;
        
        buffer.beginDraw();
        
        // Animated background
        float pulse = (sin((millis() - startTime) * 0.005) + 1) * 0.5;
        buffer.background(lerpColor(backgroundColor1, backgroundColor2, pulse));
        
        // Game title
        buffer.fill(255);
        buffer.textSize(64);
        buffer.textAlign(CENTER, CENTER);
        buffer.text(gameTitle, width/2, height/3);
        
        buffer.textSize(24);
        buffer.text("Version " + gameVersion, width/2, height/3 + 50);
        
        // Loading message
        buffer.textSize(20);
        buffer.fill(200);
        buffer.text(message, width/2, height/2 - 30);
        
        // Progress bar
        float barWidth = width * 0.6;
        float barX = width/2 - barWidth/2;
        float barY = height/2 + 20;
        
        // Glow effect
        for (int i = 3; i > 0; i--) {
            buffer.fill(red(progressBarColor), green(progressBarColor), blue(progressBarColor), 30 / i);
            buffer.noStroke();
            buffer.rect(barX - i, barY - i, barWidth + i*2, 30 + i*2, 15);
        }
        
        // Bar background
        buffer.fill(60);
        buffer.stroke(150);
        buffer.strokeWeight(2);
        buffer.rect(barX, barY, barWidth, 30, 10);
        
        // Bar fill
        buffer.noStroke();
        buffer.fill(progressBarColor);
        buffer.rect(barX + 2, barY + 2, (barWidth - 4) * progress, 26, 8);
        
        // Percentage
        buffer.fill(255);
        buffer.textSize(20);
        buffer.text(int(progress * 100) + "%", width/2, barY + 14);
        
        // Random tip
        if (tips.length > 0) {
            buffer.fill(150);
            buffer.textSize(18);
            int tipIndex = int(progress * (tips.length - 1));
            buffer.text("[!] " + tips[tipIndex], width/2, height - 50);
        }
        
        buffer.endDraw();
        
        // Draw to screen
        image(buffer, 0, 0);
    }
    
    void deactivate() {
        active = false;
    }
    
    boolean isActive() {
        return active;
    }
}
