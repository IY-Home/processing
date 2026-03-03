GameManager gameManager;

void setup() {
    fullScreen();
    pixelDensity(displayDensity()); 

    // Create and initialize game manager
    gameManager = createGameManager();
    windowTitle(gameManager.programName + " v" + gameManager.version);
    gameManager.init();
}

void draw() {
    gameManager.update();
}
