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
    float hunger; // 0-100, increases over time
    float money; // Money amount
    int lastHungerUpdate; // Timer for hunger increase
    float velocityHungerUsed = 500; // Inversely proportional to hunger increase speed
    int hungerIncreaseRate = 60; // Frames between hunger increase (1 second at 60fps)
    float hungerIncreaseAmount = 0.25; // How much hunger increases each time

    float bobOffset = 0;
    float bobSpeed = 0.08;  // How fast to bob
    float bobAmount = 3;    // How many pixels to bob
    boolean wasMoving = false;

    // Custom controls (can override parent if needed)
    int leftKey = LEFT;
    int rightKey = RIGHT;
    int upKey = UP;
    int downKey = DOWN;
    int shiftKey = SHIFT;
    Boolean mouseControls = true;

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
        if (!hasHungerAndMoney) return;
        
        // Increase hunger based on velocity (more movement = more hunger)
        hunger += abs(this.velocity.x / velocityHungerUsed);

        // Increase hunger at regular intervals
        if ((int)(frameCount/(frameRate/60)) - lastHungerUpdate >= hungerIncreaseRate) {
            hunger += hungerIncreaseAmount;
            lastHungerUpdate = (int)(frameCount/(frameRate/60));

            // Cap hunger at 100
            if (hunger > 100) {
                hunger = 100;
            }

            // Check for game over (hunger reaches 100)
            if (hunger >= 100) {
                gameOver();
            }
        }
    }
    void setControls(int left, int right, int up, int down, int shift, boolean mouse) {
      this.leftKey = left;
      this.rightKey = right;
      this.upKey = up;
      this.downKey = down;
      this.shiftKey = shift;
      this.mouseControls = mouse;
    }
    // Game over method when hunger hits 100
    void gameOver() {
        println(this.firstName + " starved!");
        exit(); // Quit the game
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
            ArrayList<Thing> cupboardsInRange = new ArrayList<Thing>();
            
            for (Thing thing : gameManager.objects) {
                if (thing instanceof Cupboard && thing.show && thing.sceneIn == this.sceneIn) {
                    float distance = abs(this.position.x - thing.position.x);
                    if (distance <= gameManager.window.physics.GRAB_RANGE) {
                        cupboardsInRange.add(thing);
                    }
                }
            }
            
            // Sort cupboards by distance
            cupboardsInRange.sort((a, b) -> {
                float distA = abs(this.position.x - a.position.x);
                float distB = abs(this.position.x - b.position.x);
                return Float.compare(distA, distB);
            });
            
            // Try each cupboard until one can be grabbed
            for (Thing cupboard : cupboardsInRange) {
                if (this.grab(cupboard)) {
                    return;  // Successfully grabbed a cupboard!
                }
            }
        }
        
        // SECOND PRIORITY: Find other potential objects in range
        ArrayList<Thing> candidates = new ArrayList<Thing>();
        
        for (Thing thing : gameManager.objects) {
            if (thing != null && thing != this && thing.show && thing.sceneIn == this.sceneIn) {
                float distance = abs(this.position.x - thing.position.x);
                
                // Skip consumed lunchboxes
                if (thing instanceof Lunchbox) {
                    Lunchbox lunchboxThing = (Lunchbox) thing;
                    if (lunchboxThing.consumed) {
                        continue;
                    }
                }
                
                if (distance <= gameManager.window.physics.GRAB_RANGE && !thing.occupied) {
                    // Store with distance for sorting
                    candidates.add(thing);
                }
            }
        }
        
        // Sort by distance (closest first)
        candidates.sort((a, b) -> {
            float distA = abs(this.position.x - a.position.x);
            float distB = abs(this.position.x - b.position.x);
            return Float.compare(distA, distB);
        });
        
        // Try each candidate in order until one is successfully grabbed
        for (Thing thing : candidates) {
            if (this.grab(thing)) {
                return;  // Successfully grabbed something!
            }
        }
        
    }

    // Enhanced grab method
    Boolean grab(Thing thing) {
        if (thing == null || thing.sceneIn != this.sceneIn || !thing.show) return false;
        
        // Check if it's a Lunchbox and already consumed
        if (thing instanceof Lunchbox) {
            Lunchbox lunchboxThing = (Lunchbox) thing;
            if (lunchboxThing.consumed) {
                return false; // Don't grab consumed lunchboxes
            }
        }
        
        // Call parent grab method
        return super.grab(thing);
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

    // Enhanced controls method with chair, jumping, and SHIFT interactions
    void controls() {
        // Handle SHIFT interactions with grabbed gameManager.objects
        if (gameManager.keyManager.isKeyPressed(shiftKey) && grabbed && grabObj instanceof Interactable) {
            // Check if enough time has passed since last SHIFT press
            if (millis() - lastShiftPress >= shiftCooldown) {
                lastShiftPress = millis(); // Record the time  
                ((Interactable) grabObj).onInteract(this);
                return; // Exit early to prevent other SHIFT actions
            }
        }

        // Jump/up movement
        if (gameManager.keyManager.isKeyPressed(upKey) || (mousePressed && mouseButton == CENTER && mouseControls)) {
            if (this.rested || this.position.y >= height*gameManager.window.getGroundHeightAt(position.x) - groundHeightOffset) {
                this.velocity.y = -50;
                this.rested = false;

                // If standing on chair, get off when jumping
                if (standingOnChair != null) {
                    this.getOffChair();
                }
            }
            this.jumping = true;
        } else {
            this.jumping = false;

            // Get off chair with DOWN or UP key
            if (standingOnChair != null && (gameManager.keyManager.isKeyPressed(upKey) || gameManager.keyManager.isKeyPressed(downKey))) {
                this.getOffChair();
            }
            // Grab/release gameManager.objects
            else if (gameManager.keyManager.isKeyPressed(downKey) || (mousePressed && mouseButton == RIGHT && mouseControls)) {
                if (millis() - this.grabms >= 500) {
                    this.grabms = millis();
                    if (this.grabbed) {
                        this.release();
                    } else {
                        this.grabClosest(gameManager.objects);
                    }
                }
            } else if (gameManager.keyManager.isKeyPressed(rightKey) || (mousePressed && mouseX >= width / 2 && mouseControls)) {
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
                
            } else if (gameManager.keyManager.isKeyPressed(leftKey) || (mousePressed && mouseControls)) {
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
            } else {
                this.velocity.x = 0;
                this.acceleration.x = 0;
            }
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
        this.update();
        this.updateHunger();
        this.display();
        this.controls();
        this.checkEdges();
        this.checkObj();
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
    image(gameManager.imageManager.getImage(imagePath), this.position.x, this.position.y - 128);
  }
 
}
