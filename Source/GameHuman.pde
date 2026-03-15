// Game Human class - extends BasicHuman with additional game mechanics 
class GameHuman extends Human {
    // Basic attributes
    String firstName, lastName, gender;
    int age;
    float speed;
    Boolean sleeping, jumping;
    Chair standingOnChair = null;

    // Hunger and money attributes
    Boolean hasHungerAndMoney = true;
    float hunger;
    float money; // Money amount
    float maxHunger = 100;
    int lastHungerUpdate; // Timer for hunger increase
    float velocityHungerUsed = 500; // Inversely proportional to hunger increase speed
    int hungerIncreaseRate = 60; // Frames between hunger increase (1 second at 60fps)
    float hungerIncreaseAmount = 0.25; // How much hunger increases each time
    boolean isDead = false;

    float bobOffset = 0;
    float bobSpeed = 0.08;  // How fast to bob
    float bobAmount = 3;    // How many pixels to bob
    boolean wasMoving = false;

    GameHuman(String firstName, String lastName, String gender, int age, color hairColor,
        color shirtColor, color pantColor, color shoeColor, float speed, float money, float posX, int sceneIn) {
        // Call parent constructor with name
        super(firstName, hairColor, shirtColor, pantColor, shoeColor, posX, sceneIn);
        
        this.updateInBackground = true;
        
        // Set additional properties
        this.firstName = firstName;
        this.lastName = lastName == null || lastName.isEmpty() ? "" : lastName;
        this.gender = gender == null || gender.isEmpty() ? "boy" : gender;
        this.age = age;
        this.speed = (speed > 0 ? speed : 2);
        
        // Initialize hunger and money
        this.hunger = 0;
        this.money = money;
        this.lastHungerUpdate = (int)(frameCount/(frameRate/60));
        this.sleeping = false;
        this.jumping = false;
        this.standingOnChair = null;
    }

    // Update hunger over time
    void updateHunger() {
        if (!hasHungerAndMoney) { this.trackedIndicatorHeight = 50; return; };
        
        this.trackedIndicatorHeight = 108;

        // Increase hunger based on velocity (more movement = more hunger)
        hunger += abs(this.velocity.x / velocityHungerUsed);

        // Increase hunger at regular intervals
        if ((int)(frameCount/(frameRate/60)) - lastHungerUpdate >= hungerIncreaseRate) {
            hunger += hungerIncreaseAmount;
            lastHungerUpdate = (int)(frameCount/(frameRate/60));

            if (hunger >= maxHunger) {
                starve();
            }
        }
    }
    
    // Starve method when hunger hits maxHunger
    void starve() {
        gameManager.messageBox.showAlert(this.firstName + " starved!");
        this.isDead = true;
        this.show = false;
        this.hasPhysics = false;
        this.speed = 0;
        this.money = 0;
    }

    void respawn() {
        if (this.isDead) {
            this.isDead = false;
            this.show = true;
            this.hasPhysics = true;
            this.hunger = maxHunger / 2;
            this.speed = 2;
            gameManager.messageBox.showAlert(this.firstName + " respawned!");
        }
    }

    // Method to eat food
    void eatFood(Lunchbox food) {
        if (!hasHungerAndMoney) return;
        
        if (money >= food.price) {
            // Consume the food
            hunger -= food.energyValue;
            money -= food.price;

            // Make sure hunger doesn't go below 0
            if (hunger < 0) {
                hunger = 0;
            }

            // Hide the food
            food.consumed = true;
            food.hide();

            println(firstName + " ate a lunchbox! Hunger: " + nf(hunger, 0, 1) + ", Money: $" + nf(money, 0, 2));
        } else {
            println("Not enough money! Need $" + food.price + ", but only have $" + nf(money, 0, 2));
        }
    }

    // Enhanced grabClosest method with SHIFT priority for Cupboard
    void grabClosest(ArrayList<Thing> objects) {
        this.release();  // Release current object
        
        // FIRST PRIORITY: Cupboard when SHIFT is pressed
        if (gameManager.keyManager.isKeyPressed(shiftKey)) {
            // Find all cupboards in range
            ArrayList<Thing> cupboardsInRange = this.getClosestObjects(objects, grabRange);
            
            // Try each cupboard until one can be grabbed
            for (Thing cupboard : cupboardsInRange) {
                if (cupboard instanceof Cupboard && this.grab(cupboard)) {
                    return;  // Successfully grabbed a cupboard!
                }
            }
        }
        
        // SECOND PRIORITY: Find other potential objects in range with default function
        super.grabClosest(objects);
        
    }

    // Get off a chair
    void getOffChair() {
        if (standingOnChair != null) {
            standingOnChair.occupied = false;
            standingOnChair.restedObj = null;
            this.position.y -= 20; // Move slightly up when getting off
            standingOnChair = null;
            this.rested = false;
        }
    }

    // Stand on a chair
    void standOnChair(Chair chair) {
        this.standingOnChair = chair;
        this.rested = true;
        this.velocity.set(0, 0);
        this.jumping = false;
        
        // Ensure proper position
        this.position.x = chair.position.x;
        this.position.y = chair.position.y - 260;
    }

    // Draw money display
    void drawMoney() {
        if (!hasHungerAndMoney) return;
        
        fill(gameManager.window.scenes.getAs(sceneIn, Integer.class, color(255)) < -13500000 ? 255 : 0);
        textSize(18);
        textAlign(CENTER);
        text("$" + nf(money, 0, 2), position.x, position.y - 96);
        textAlign(LEFT); // Reset alignment
    }


    // Enhanced display method
    void display() {
        // Check if we're stationary and not jumping
        boolean isStationary = (velocity.x == 0 && standingOnChair == null && grabObj == null);
        
        pushMatrix();
        
        if (isStationary) {
            // Bob up and down using sine wave
            bobOffset += bobSpeed;
            float bobY = sin(bobOffset) * bobAmount;
            translate(0, bobY);
        } else {
            // Reset bobbing when moving
            bobOffset = 0;
        }
        
        // Call parent display to draw the human
        super.display();
        
        popMatrix();
        
        // Draw money and hunger (these shouldn't bob)
        if (hasHungerAndMoney) {
            drawMoney();
            drawStatBar("Hunger", 100, 12, position.x - 100 / 2.4, position.y - 128, 
                       gameManager.window.scenes.getAs(sceneIn, Integer.class, color(255)) < -13500000 ? 255 : 0, 
                       getHungerBarColor(), 100, (100-hunger));
        }
    }
    
    color getHungerBarColor() {
        float hungerPercent = hunger / 100.0;
        if (hungerPercent < 0.3) return color(0, 255, 0);
        else if (hungerPercent < 0.7) return color(255, 255, 0);
        else return color(255, 0, 0);
    }

    @Override
    void leftKeyDown() {
        float groundAngle = gameManager.window.getGroundAngleAt(position.x);
        float baseSpeed = -speed / (frameRate/60);
        
        float steepness = abs(groundAngle);
        float maxSteepness = 0.7;
        
        float slopeEffect;
        if (groundAngle > 0) { 
            slopeEffect = 1.0 - 1.5 * pow(steepness / maxSteepness, 2);
        } else { 
            slopeEffect = 1.0 + 1.2 * pow(steepness / maxSteepness, 2);
        }
        
        slopeEffect = constrain(slopeEffect, 0.15, 4.0);
        this.acceleration.x = baseSpeed * slopeEffect;
    }

    @Override
    void rightKeyDown() {
        float groundAngle = gameManager.window.getGroundAngleAt(position.x);
        float baseSpeed = speed / (frameRate/60);
        
        float steepness = abs(groundAngle);
        float maxSteepness = 0.7;
        
        float slopeEffect;
        if (groundAngle > 0) {
            slopeEffect = 1.0 + 1.2 * pow(steepness / maxSteepness, 2);
        } else {
            slopeEffect = 1.0 - 1.5 * pow(steepness / maxSteepness, 2);
        }
        
        slopeEffect = constrain(slopeEffect, 0.15, 4.0);
        this.acceleration.x = baseSpeed * slopeEffect;
    }

    @Override
    void upKeyDown() {
        super.upKeyDown();

        // If standing on chair, get off when jumping
        if (standingOnChair != null) {
            this.getOffChair();
        }
    }

    // Check object interactions
    void checkObj() {
        super.checkObj();
        // If standing on chair, maintain position
        if (standingOnChair != null) {
            this.position.x = standingOnChair.position.x;
            this.position.y = standingOnChair.position.y - 260;
            this.velocity.set(0, 0);
            this.rested = true;
        }
    }

    // Main update loop for human
    void live() {
        if (!isDead) {
            this.update();
            this.updateHunger();
            this.display();
            this.controls();
            this.checkEdges();
            this.checkObj();
        }
    }
    
    // Background update loop for human
    void backgroundUpdate() {
        this.update();
        this.updateHunger();
    }
}

class ImageHuman extends Human {
  String imagePath;
  ImageHuman(String name, String filename, float posX, int sceneIn) {
    super(name, color(255), color(255), color(255), color(255), posX, sceneIn);
    this.imagePath = filename;
    gameManager.imageManager.addImage(imagePath, imagePath, 360, 360);
  }
  void display() {
    PGraphics drawImage = gameManager.imageManager.getImage(imagePath);
    image(drawImage, this.position.x - (drawImage.width/2), this.position.y - 128);
  }
 
}
