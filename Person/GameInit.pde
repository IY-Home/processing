GameManager createGameManager() {
    // Executed at the very start of the program, with definition gameManager = createGameManager.  
    // If you need to, put any other code you want to have executed at the very start of the program here.
    
    // Change Game Manager variables, e.g.
    GameManagerWithLoading gm = new GameManagerWithLoading("My Game", "2.0");
    
    gm.messageBox.visible = true;
    
    // You can change constants too, e.g.
    // gm.startupMessage = "Welcome to my game!"; 
    // gm.keyManager = new myCustomKeyManager();
    
    // Return any object of a class that extends GameManager. Default: return new GameManager().
    return gm; 
}

Boolean initLoadingScreen(LoadingManager loader) {
    String[] loadingTips = new String[] {
        "Press DOWN to grab objects",
        "Press SHIFT to interact with held objects",
        "You can stand on chairs by pressing SHIFT while holding one",
        "Eat food when hungry",
        "Doors lead to new scenes",
        "Enter scene 6 to get the prize!",
        "You can throw balls with SHIFT",
        "You can go faster if you jump when moving",
        "Balls bounce off each other!",
        "Get to scene 6 to get the prize!",
        "You can throw balls by pressing SHIFT while holding one",
        "Open cupboards to find hidden items",
        "Store items in cupboards by closing them nearby"
    };    
    loader.loadingTips = loadingTips;
    loader.progressBarColor = color(255, 200, 100); // Yellow
    
    return true; // Enable loading screen
}

void createScenes(Window window) {
    // Colors for different times of day
    color day = color(90, 210, 255);
    color evening = color(50, 95, 135);
    color night = color(18, 19, 65);
    
    String beach = "backgrounds/beach.png";  // only the file name is needed
    
    // Method 1: Pass parallel arrays
    window.addScenes(
        new Object[]{day, beach, evening, color(240,250,255), day, night, color(255, 200, 0)},
        new Boolean[]{true, false, true, true, true, true, true}
    );
    
    // OR Method 2: Set ground for specific scenes after bulk add
    // window.addScenes(new Object[]{day, beach, night, color(240,250,255), evening, color(240,250,255), night}, true);
    // window.setSceneGround(1, false); // Scene 1 (beach) - no ground
    // window.setSceneGround(7, false); // Scene 7 - no ground
    
    window.groundHeightSampleRate = 1; 
    
    window.addGroundKeyframe(2, 0, 0.8);    // Start at 80%
    window.addGroundKeyframe(2, 200, 0.8);  // Still 80%, slope starts
    window.addGroundKeyframe(2, 750, 0.5);  // Top of the hill
    window.addGroundKeyframe(2, 1000, 0.8); // Back to 80% at end of the hill
    
    // Make ground bumpy like real mountain
    for (float x = 0; x < width; x += 20) {
          float shake = random(-0.02, 0.02);
          float current = gameManager.window.getGroundHeightAt(2, x);
          window.addGroundKeyframe(2, x, current + shake);
    }
    
    // Make stairs
    window.createStairs(3, 300, 600, 0.8, 0.45, 50, 0.05);
    window.createStairs(3, 700, 1000, 0.45, 0.8, 50, 0.05);
    window.addGroundKeyframe(3, width, 0.8); 
    
    window.addGroundKeyframe(5, 0, 0.8);    // Start at 80%
    window.addGroundKeyframe(5, 450, 0.8);  // Still at 80%
    window.addGroundKeyframe(5, 451, 0.95); // Hole, drop to 95%
    window.addGroundKeyframe(5, 699, 0.95); // Still hole, 95%
    window.addGroundKeyframe(5, 700, 0.8); // Hole ends, 80%
    window.addGroundKeyframe(5, 1000, 0.8);    // Another hole starts at 80%
    window.addGroundKeyframe(5, 1050, 0.95);  // Drops to 95%
    window.addGroundKeyframe(5, 1100, 0.8); // Hole ends, 80%
    
    // Make ground bumpy like real terrain
    for (float x = 0; x < width; x += 20) {
          float shake = random(-0.01, 0.01);
          float current = gameManager.window.getGroundHeightAt(5, x);
          window.addGroundKeyframe(5, x, current + shake);
    }
    
    window.addGroundKeyframe(6, 0, 0.8);
    window.addGroundKeyframe(6, 600, 0.8);
    window.addGroundKeyframe(6, 610, 0.6);
    window.addGroundKeyframe(6, width, 0.6);
    
    // Configure window
    window.scene = 0;        // initial scene
    window.scenes.setLoop(true);
    
    // window.cursorColor = color(0, 120, 255);
    window.drawingCustomCursor = true;

    // You can change physics values, e.g.
    // window.physics.GRAVITY = 3f;
    // window.physics.GRAB_RANGE = 60;
    
    // You can also customize other window properties, e.g.
    // window.frameSpeed = 0.5;
    // window.groundColor = color(200, 100, 0);
    // window.trashScene = 999;
    // window.cursorSize = 40;
}

void createHumans(ArrayList <Human> humans) {
    // Create main human character with $200 starting money
    String[] humanName = {"Isaac", "Tan"};
    String humanGender = "boy";
    int humanAge = 10;
    float humanSpeed = 2.5;
    float humanMoney = 200;
    int humanScene = 0;
    GameHuman isaac = new GameHuman(humanName[0], humanName[1], humanGender, humanAge, 
                      color(0), color(0, 0, 255), color(50), color(0), 
                      humanSpeed, humanMoney, width * 0.68, humanScene);
    humans.add(isaac);

    String humanName2 = "Nick";
    humanScene = 0;
    Human nick = new Human(humanName2, color(200, 200, 0), color(255, 0, 0), color(50), color(0), width * 0.3, humanScene);
    // Hide Nick for now, so comment out: humans.add(nick);
    
    String humanName3 = "Joe";
    humanScene = 0;
    ImageHuman joe = new ImageHuman(humanName2, "objects/person.png", width * 0.3, humanScene);
    // Hide Joe for now, so comment out: humans.add(joe);
}

void createObjects(ArrayList <Thing> things) {
    color woodColor = color(200, 100, 0);  

    // Add doors for scene transitions
    things.add(new Door(true, width * 0.9, width * 0.1, woodColor, 0, 1));
    things.add(new Door(true, width * 0.9, width * 0.1, woodColor, 1, 2));
    things.add(new Door(true, width * 0.9, width * 0.1, woodColor, 2, 3));
    things.add(new Door(true, width * 0.9, width * 0.1, woodColor, 3, 4));
    things.add(new Door(true, width * 0.9, width * 0.1, woodColor, 4, 5));
    things.add(new Door(true, width * 0.9, width * 0.1, color(192, 168, 0), 5, 6));
    Door winningDoor = new Door(true, width * 0.9, width * 0.1, color(0, 200, 255), 6, 0);
    winningDoor.isOneWay = true;
    things.add(winningDoor);
    
    Lunchbox[] myFood = new Lunchbox[3];
    myFood[0] = new Lunchbox("Pizza", color(255, 100, 50), 0, 60, 15, 25);
    myFood[1] = new Lunchbox("Burger", color(150, 75, 0), 0, 60, 12, 22);
    myFood[2] = new Lunchbox("Salad", color(50, 200, 50), 0, 60, 8, 15);
    
    // Add furniture and objects
    things.add(new Cupboard(color(120, 60, 20), 840, 255, 100, 0, 100));
    things.add(new PreFilledCupboard("Food", color(180), 651, 180, 120, 3, 60, myFood));
    things.add(new BouncyBall("objects/football.png", random(65, 80), 200, 0.85, 0));
    things.add(new BouncyBall("objects/basketball.png", random(65, 80), 800, 0.85, 1));
    things.add(new Chair(woodColor, 700, 0));
    Chair chair1 = new Chair(woodColor, 900, 1);
    Shirt shirt1 = new Shirt(color(255, 0, 0), 900, 1);
    chair1.putObjOnChair(shirt1);
    things.add(chair1);
    things.add(shirt1);
    things.add(new Drone(color(100, 100, 100), 500, 4));
    
    // Add food items (Lunchboxes)
    things.add(new Lunchbox("Chicken", color(255, 150, 0), 300, 0, 15, 25));
    things.add(new Lunchbox("Veggies", color(0, 200, 20), 500, 0, 0, 15));
    things.add(new Lunchbox("Pork", color(200, 0, 40), 700, 1, 20, 35));
    things.add(new Lunchbox("Beef", color(128, 96, 0), 300, 2, 30, 50));
    
    
    // Add CashBags with different passcodes
    things.add(new CashBag(color(50, 200, 50), 400, 0, 50, "1234", "First 4 numbers!"));  // $50, passcode 1234
    things.add(new CashBag(color(200, 200, 50), 600, 1, 100, "Hello", "A common English greeting!")); // $100, passcode 2468
    things.add(new CashBag(color(50, 50, 200), 800, 2, 200, "P@55$ec6re", "You shall never guess it.")); // $200, passcode ????????
    things.add(new CashBag(color(255, 200, 0), width*0.75, 6, 1000, "Iwon!", "You found the prize! The password is 'Iwon!'.")); // $1000, prize at scene 6. After the 'holey' scene 5.
   
}

void loop() {
    // If humans fall into a hole, they die.
    for (int i = gameManager.mainHumans.size() - 1; i >= 0; i--) {
        Human human = gameManager.mainHumans.get(i);
        if (human instanceof GameHuman) {  // Only game humans die
            if (human.position.y > height*0.9 - human.groundHeightOffset) {
                GameHuman gh = (GameHuman) human;
                gameManager.messageBox.showAlert("Oops, " + gh.firstName + " fell into a hole and died!");
                gameManager.messageBox.showAlert("Remember, the prize awaits behind that golden door!");
                gameManager.window.scene = 0;
                gh.sceneIn = 0;
                gh.position.y = 0;
                gh.velocity.x = -40;
                gh.acceleration.x = -40;
                gameManager.messageBox.showAlert(gh.firstName + " has respawned at the starting scene. Be careful this time!");
                delay(100);
            }
        }
    }
}
