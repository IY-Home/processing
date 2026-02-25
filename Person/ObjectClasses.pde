// Ball object class
class Ball extends Thing {
    color ballColor;
    float size;
    float radius;

    Ball(color ballColor, float size, float posX, int sceneIn) {
        this.ballColor = ballColor;
        this.size = size;
        this.radius = size / 2;
        this.initialize();
        this.position = new PVector(posX, height * random(0.3, 0.5));
        this.velocity = new PVector(0, 0);
        this.acceleration = new PVector(0, 0);
        this.grabbable = true;
        this.occupied = false;
        this.sceneIn = sceneIn;
        this.hasPhysics = true; // Ball has physics
        this.groundHeightOffset = radius;
    }

    // Display the ball - REQUIRED by abstract class Thing
    void display() {
        if (this.show) {
            strokeWeight(2);
            fill(ballColor);
            ellipse(this.position.x, this.position.y, size, size);
        }
    }
}

class BouncyBall extends Ball implements Interactable {
    Boolean rebounding = false;
    String imagePath;
    
    BouncyBall(String imagePath, float size, float posX, float elasticity, int sceneIn) {
      super(color(255), size, posX, sceneIn);
      this.elasticity = elasticity;
      this.imagePath = imagePath;
      gameManager.imageManager.addImage(imagePath, imagePath, round(this.radius*2), round(this.radius*2));
      this.checkTouchRadius = 150; // check objects 70 px from self
      this.checkTouchY = true;
      this.groundHeightOffset = this.radius * 0.6;
    }
    void display() {
      push();
      imageMode(CENTER);
      image(gameManager.imageManager.getImage(imagePath), this.position.x, this.position.y);
      imageMode(CORNER);
      pop();
    }
    void update() {
      super.update();
      if (this.velocity.x == 0) {
        this.rebounding = false;
      }
    }
    void onTouch(Thing other, float distance) {
        if (other instanceof BouncyBall && !(((BouncyBall) other).rebounding) && (((BouncyBall) other).radius) + this.radius >= distance) {
                if (other.position.x >= this.position.x) {
                    other.position.x = this.position.x + this.radius + 20;
                    other.velocity.x = 2;
                    this.velocity.x = -2;
                } else if (other.position.x < this.position.x) {
                    other.position.x = this.position.x - this.radius - 20;
                    other.velocity.x = -2;
                    this.velocity.x = 2;
                }
                this.rebounding = true;
                ((BouncyBall) other).rebounding = true;
        }
    }
    void onGrab(Human human) {} void onRelease() {} boolean isGrabbable() { return true; }
    void onInteract(Human human) {
      int direction = (round(random(0,1)) == 1) ? 1 : -1;
      if (gameManager.keyManager.isKeyPressed(LEFT)) direction = -1;
      if (gameManager.keyManager.isKeyPressed(RIGHT)) direction = 1;
      human.velocity.x *= -(direction);
      human.release();
      this.velocity.set(random(10, 160)*direction, random(-200, -600));
    }

}


// Shirt object class
class Shirt extends Thing implements Interactable {
    color shirtColor;

    Shirt(color shirtColor, float posX, int sceneIn) {
        this.shirtColor = shirtColor;
        this.initialize();
        this.position = new PVector(posX, height * 0.3);
        this.velocity = new PVector(0, 0);
        this.acceleration = new PVector(0, 0);
        this.elasticity = 0.75;
        this.grabbable = true;
        this.occupied = false;
        this.sceneIn = sceneIn;
        this.hasPhysics = true; // Shirt has physics
    }

    // Display the shirt - REQUIRED by abstract class Thing
    void display() {
        if (this.show) {
            strokeWeight(2);
            fill(this.shirtColor);
            rect(this.position.x - 35, this.position.y - 64, 70, 100);
        }
    }
    
    void onGrab(Human human) {
    
    }

    // Interactable interface implementation
    void onInteract(Human human) {
        // Swap colors with human
        color orgColor = human.shirtColor;
        human.shirtColor = this.shirtColor;
        this.position.add(new PVector(25, 0));
        this.shirtColor = orgColor;
    }

    boolean isGrabbable() {
        return this.grabbable && !this.held && !this.occupied;
    }

    void onRelease() {
    }

}

// Chair object class
class Chair extends Thing implements Interactable {
    color chairColor;
    Thing restedObj;
    boolean humanOnChair = false;

    Chair(color chairColor, float posX, int sceneIn) {
        this.chairColor = chairColor;
        this.initialize();
        this.position = new PVector(posX, height*gameManager.window.getGroundHeightAt(sceneIn, posX));
        this.velocity = new PVector(0, 0);
        this.elasticity = 0;
        this.grabbable = true;
        this.occupied = false;
        this.restedObj = null;
        this.sceneIn = sceneIn;
        this.checkTouchRadius = 150;
        this.checkTouchY = true;
        this.friction = 0.95;
        this.drawInBackground = true;
        // this.isStatic = true;
    }

    // Display the chair - REQUIRED by abstract class Thing
    void display() {
        if (this.show) {
            strokeWeight(2);
            fill(chairColor);
            rect(this.position.x - 40, this.position.y - 60, 20, 92);
            rect(this.position.x + 20, this.position.y - 60, 20, 92);
            rect(this.position.x - 45, this.position.y - 60, 90, 20);
        }
    }

    void putObjOnChair(Thing other) {
          other.rested = true;
          other.position.x = this.position.x;
          other.position.y = this.position.y - (other instanceof Ball ? (36 + ((Ball)other).radius * 1.075) : 80);
          other.velocity.x = 0;
          this.occupied = true;
          this.restedObj = other;
    }

    void onTouch(Thing other, float distance) {
      // HUMAN: do nothing
        if (other instanceof Human) return;
        
        if (abs(this.velocity.x) < 0.2) {
            if (millis() - other.lastReleasedMs < 360 && !this.occupied && other.position.y <= this.position.y) {
                putObjOnChair(other);
            } else if (millis() - other.lastReleasedMs < 360) {
                if (this.occupied) {
                    other.position.y = height*gameManager.window.getGroundHeightAt(position.x);
                    if (other.velocity.x == 0) {
                        other.position.x = other.position.x <= this.position.x ? this.position.x - 110 : this.position.x + 110;
                        other.velocity.x = other.position.x <= this.position.x ? -1.2 : 1.2;
                    } else {
                        other.velocity.x *= -0.8;
                    }
                } else {
                    other.velocity.y *= -0.8;
                    other.velocity.x *= -0.8;
                }
            }
        }

        // Clear occupied status if rested object is no longer resting
        if (restedObj == null || !restedObj.rested || restedObj.held) {
            this.occupied = false;
            this.humanOnChair = false;
            this.restedObj = null;
        }
    }

    // Press SHIFT to stand on chair
    void onInteract(Human human) {
      this.humanStand(human);
    }
    void humanStand(Human human) {
      if (human instanceof GameHuman) {
        GameHuman gameHuman = (GameHuman) human;
        gameManager.messageBox.showEvent("Human standing on chair!");
        
        // Calculate proper standing position
        float standX = this.position.x;
        float standY = this.position.y - 260; // Standing on the chair seat
        
        // Set human position properly
        gameHuman.position.x = standX;
        gameHuman.position.y = standY;
        
        gameHuman.standOnChair(this);
        this.occupied = true;
        this.restedObj = gameHuman;
        this.humanOnChair = true;
        
        // Make sure human releases the chair
        gameHuman.release();
        
        return;
      }
    }
    void update() {
      super.update();
      if (restedObj == null || !restedObj.rested || restedObj.held) {
            this.occupied = false;
            this.humanOnChair = false;
            this.restedObj = null;
      }
    }
    // Interactable interface implementation
    void onGrab(Human human) {
        this.held = true;
    }

    boolean isGrabbable() {
        return this.grabbable && !this.held && !this.occupied;
    }

    void onRelease() {
    }
}

// Door object class (for scene transitions)
class Door extends Thing implements Interactable {
    int sceneFrom; // Start scene
    int sceneDes; // Destination scene
    // Note: the two are interchangable.
    float posXFrom; // Previous X position
    float posXDes; // New X position in destination scene
    color frameColor;
    
    private int currentDisplayScene;
    private int targetScene;
    private float posXNew;
    
    boolean isOneWay;

    Door(boolean show, float posX, float posXDes, color frameColor, int sceneIn, int sceneDes) {
        this.show = show;
        this.initialize();
        this.position = new PVector(posX, height*gameManager.window.getGroundHeightAt(sceneIn, posX));
        this.velocity = new PVector(0, 0);
        this.elasticity = 0;
        this.grabbable = false;
        this.occupied = false;
        this.drawInBackground = true; 
        this.drawBehindHumans = true; // Behind humans
        this.sceneDes = sceneDes;
        this.sceneIn = sceneIn;
        this.sceneFrom = sceneIn;
        this.posXFrom = posX;
        this.posXDes = posXDes;
        this.targetScene = sceneDes;
        this.posXNew = posXDes;
        this.checkTouchRadius = 80;
        this.checkTouchY = true;
        this.isOneWay = false;
        this.frameColor = frameColor;
        this.hasPhysics = false; // Door is static
        this.updateInBackground = true;
    }

    void display() {
        if (show) {
            push();
            checkDestination(this);
            fill(frameColor);
            strokeWeight(2);
            stroke(40);
            rect(this.position.x - 45, this.position.y - 255, 15, 292);
            rect(this.position.x + 30, this.position.y - 255, 15, 292);
            rect(this.position.x - 45, this.position.y - 255, 90, 15);
            rect(this.position.x - 45, this.position.y + 26, 90, 15);
            fill(gameManager.window.scenes.getAs(targetScene, Integer.class, this.frameColor));
            rect(this.position.x - 30, this.position.y - 240, 60, 265);
            strokeWeight(1);
            pop();
        }
    }

    void checkDestination(Thing other) {
        this.targetScene = (other.sceneIn == sceneFrom || this.isOneWay ? sceneDes : sceneFrom);
        this.posXNew = (other.sceneIn == sceneFrom || this.isOneWay ? posXDes : posXFrom);      
    }

    // Check collision with other objects - REQUIRED by abstract class Thing
    void onTouch(Thing other, float distance) {
        checkDestination(other);
        if (!(other instanceof Door) && !(other instanceof Human)) {
            other.position.x = posXNew < width / 2 ? posXNew + 120 + random(-20, 20) : posXNew - 120 - random(-20, 20);
            other.sceneIn = targetScene;
            other.occupied = false;
        }
    }

    // Interactable interface implementation
    void onGrab(Human human) {  
        checkDestination(human);
        human.sceneIn = targetScene;
        gameManager.window.goToScene(targetScene);
        gameManager.messageBox.showEvent(human.name + " entered scene " + targetScene + "!");
        human.position.x = this.posXNew < width / 2 ? this.posXNew + 120 + random(-20, 20) : this.posXNew - 120 - random(-20, 20);
        human.grabbed = false;
    }
    void onInteract(Human human) {
      // There is no need to press SHIFT to enter door.
    }
    boolean isGrabbable() {
        // Doors are interactable but not "grabbable" in the traditional sense
        // They trigger immediately when interacted with
        return false;
    }

    void onRelease() {
        // Doors don't need to be released since they trigger immediately
    }
    
    void backgroundUpdate() {
        if (gameManager.window.scene == sceneFrom || (gameManager.window.scene == sceneDes && !isOneWay)) {
            if (this.sceneIn != gameManager.window.scene) {
                this.sceneIn = gameManager.window.scene;
                
                // Set correct position based on which scene we're in
                if (gameManager.window.scene == sceneFrom) {
                    this.position.x = posXFrom;
                } else {
                    this.position.x = posXDes;
                }
                
                this.show = true;
            }
        } else {
            // Not in either of this door's scenes - hide it
            if (this.show) {
                this.show = false;
            }
        }
    }
    
    void update() {
        super.update();
        this.currentDisplayScene = gameManager.window.scene;
        // When in scene, make sure position is correct
        if (currentDisplayScene == sceneFrom) {
            this.position.x = posXFrom;
        } else if (currentDisplayScene == sceneDes) {
            this.position.x = posXDes;
        }
    }
}

// Cupboard/storage object class
class Cupboard extends Thing implements Interactable {
    boolean opened = false; // Whether cupboard is open
    color woodColor; // Color of the cupboard
    float cupboardHeight, cupboardWidth; // Dimensions
    ArrayList < Thing > shelves = new ArrayList < Thing > (); // Things inside
    int sceneDes; // Destination scene for stored objects

    Cupboard(color woodColor, float x, float cupboardHeight, float cupboardWidth, int sceneIn, int sceneDes) {
        this.woodColor = woodColor;
        this.initialize();
        this.position = new PVector(x, height*gameManager.window.getGroundHeightAt(sceneIn, x));
        this.velocity = new PVector(0, 0);
        this.acceleration = new PVector(0, 0);
        this.elasticity = 0.4;
        this.grabbable = false;
        this.friction = 0.95;
        this.sceneIn = sceneIn;
        this.sceneDes = sceneDes;
        this.cupboardHeight = cupboardHeight;
        this.cupboardWidth = cupboardWidth;
        // this.isStatic = true; // Cupboard is *not* static - you pick it up to open it
    }

    // Display the cupboard - REQUIRED by abstract class Thing
    void display() {
        if (!show) return;
        
        strokeWeight(2);
        fill(woodColor);
        rect(position.x - cupboardWidth / 2, position.y - cupboardHeight + 36, cupboardWidth, cupboardHeight);

        fill(lerpColor(woodColor, color(40), 0.2));
        if (opened) {
            // Draw open doors
            quad(position.x - cupboardWidth / 2, position.y - cupboardHeight + 36,
                position.x - cupboardWidth, position.y - cupboardHeight + 26,
                position.x - cupboardWidth, position.y - 20 + 38,
                position.x - cupboardWidth / 2, position.y - 20 + 56);

            quad(position.x + cupboardWidth / 2, position.y - cupboardHeight + 36,
                position.x + cupboardWidth, position.y - cupboardHeight + 26,
                position.x + cupboardWidth, position.y - 20 + 38,
                position.x + cupboardWidth / 2, position.y - 20 + 56);
        } else {
            // Draw closed doors
            rect(position.x - cupboardWidth / 2 + 2, position.y - cupboardHeight + 38, cupboardWidth / 2 - 4, cupboardHeight - 4);
            rect(position.x + 2, position.y - cupboardHeight + 38, cupboardWidth / 2 - 4, cupboardHeight - 4);
        }
    }

    void onGrab(Human human) {
    }
    // Interactable interface implementation
    void onInteract(Human human) {
        if (!opened) {
            opened = true;
            // Move objects from shelves to current scene
            for (Thing obj: shelves) {
                if (obj != null) {
                    obj.sceneIn = this.sceneIn;
                    obj.position.x = this.position.x + this.cupboardWidth;
                }
            }
            shelves.clear();
            gameManager.messageBox.showEvent("Cupboard opened");
            return;
        } else {
            shelves.clear();
            // Check for objects to store
            for (Thing obj: gameManager.objects) {
                if (obj != this) {
                    this.checkThing(obj);
                }
            }
            this.opened = false;
            gameManager.messageBox.showEvent("Cupboard closed");
        }
    }

    boolean isGrabbable() {
       return true;
    }

    void onRelease() {
        // Cupboards trigger immediately, no release needed
    }

    // Check if object should be stored in cupboard
    void checkThing(Thing other) {
        if (this.opened && !(other instanceof Cupboard) && !(other instanceof Door) && other.sceneIn == this.sceneIn) {
            float distance = PVector.dist(this.position, other.position);
            if (distance < 140 && !other.held) {
                other.position.x = this.position.x;
                shelves.add(other);
                other.sceneIn = this.sceneDes;
                other.occupied = false;
                other.rested = false;
                other.velocity.x = 0;
            } else {
                shelves.remove(other);
                other.occupied = false;
            }
        }
    }
}

// Drone object class
class Drone extends Thing implements Interactable {
    float altitude = 10; // Current altitude
    float battery = 100; // Battery percentage
    String status = "Landed"; // Current status
    float verticalSpeed = 2; // Speed of vertical movement
    float oldBattery = 0; // Old battery value for charging
    color col; // Drone color

    String message = "Use WASD keys to control\nand use R key to recharge.";

    int upKey = 87; // W
    int downKey = 83; // S
    int leftKey = 65; // A
    int rightKey = 68; // D

    // Recharging system
    boolean recharging = false;
    int rechargeStartTime = 0;
    int rechargeDuration = 300; // Frames to fully recharge

    Drone(color c, float x, int sceneIn) {
        this.position = new PVector(x, height * 0.70);
        velocity = new PVector(0, 0);
        this.sceneIn = sceneIn;
        acceleration = new PVector(0, 0);
        this.grabbable = false;
        this.col = c;
        this.hasPhysics = true; // Drone has physics (it moves)
        this.drawInForeground = true;
    }

    // Display the drone and its status - REQUIRED by abstract class Thing
    void display() {
        float wobble = sin((frameCount/(frameRate/60)) * 0.1) * 2;
        float displayY = (this.held ? position.y : map(altitude, 0, 200, height - 50, 50) + (status.equals("Flying") ? wobble : 0));

        rectMode(CENTER);
        strokeWeight(2);
        fill(col);
        rect(position.x, displayY, 60, 30);
        rectMode(CORNER);

        // Draw status info
        fill(0);
        textSize(18);
        text("Status: " + status, width / 2.2, 55);
        text("Altitude: " + nf(altitude - 10, 0, 1) + " cm", width / 2.2, 85);
        text("Battery: " + int(battery) + "%", width / 2.2, 115);
        text(message, width / 2.3, 145);
    }
    
    void onGrab(Human human) {
      if (status.equals("Flying")) human.release();
    } 
    void onRelease() {} 
    void onInteract(Human human) {}
    boolean isGrabbable() { return !(status.equals("Flying")); };

    // Update drone state
    void update() {
        // Handle recharging
        if (gameManager.keyManager.isKeyPressed(82) && status.equals("Landed") && !recharging && battery < 100) {
            recharging = true;
            rechargeStartTime = (int)(frameCount/(frameRate/60));
            status = "Recharging";
            oldBattery = battery;
            gameManager.messageBox.showEvent("Recharging started...");
        }
        if (recharging) {
            int elapsed = (int)(frameCount/(frameRate/60)) - rechargeStartTime;
            battery = map(elapsed, 0, rechargeDuration, 0, 100) + oldBattery;
            battery = constrain(battery, 0, 100);
            if (elapsed >= rechargeDuration || battery == 100) {
                recharging = false;
                battery = 100;
                status = "Landed";
                gameManager.messageBox.showEvent("Recharging complete!");
            }
        }

        acceleration.set(0, 0);
        if (!status.equals("Landed") && !recharging && battery > 0) {
            if (gameManager.keyManager.isKeyPressed(leftKey)) acceleration.x = -0.6;
            if (gameManager.keyManager.isKeyPressed(rightKey)) acceleration.x = 0.6;
        }

        if (!this.held) {
            velocity.add(acceleration);
            velocity.x *= 0.95;
            velocity.x = constrain(velocity.x, -10, 10);
            position.add(velocity);

            // Wall collision
            if (position.x <= 30) {
                position.x = 30;
                velocity.x *= -0.8;
                gameManager.messageBox.showEvent("Hit left wall.");
            } else if (position.x >= width - 30) {
                position.x = width - 30;
                velocity.x *= -0.8;
                gameManager.messageBox.showEvent("Hit right wall.");
            }

            if (abs(velocity.x) < 0.1) velocity.x = 0;

            // Handle vertical movement
            if (battery > 0 && !status.equals("Emergency Landing") && !recharging) {
                if (gameManager.keyManager.isKeyPressed(upKey) && altitude < 200) {
                    altitude += verticalSpeed;
                    if (!held) {
                        if (status.equals("Landed")) status = "Flying";
                    } else {
                        status = "Landed";
                        this.position.y = height * 0.6;
                    }
                }
                if (gameManager.keyManager.isKeyPressed(downKey) && altitude > 0) {
                    altitude -= verticalSpeed;
                    if (altitude <= 10) {
                        altitude = 10;
                        status = "Landed";
                        velocity.set(0, 0);
                        this.sceneIn = 3;
                    }
                }
            }
        }

        // Battery drain when flying
        if (!status.equals("Landed") && !recharging) {
            battery -= 0.04;
            battery = max(battery, 0);
        }

        // Emergency landing when battery empty
        if (battery <= 0 && !status.equals("Landed") && !status.equals("Emergency Landing")) {
            gameManager.messageBox.showEvent("Battery empty! Emergency landing...");
            status = "Emergency Landing";
        }

        // Handle emergency landing
        if (status.equals("Emergency Landing")) {
            altitude -= verticalSpeed * 1.2;
            if (altitude <= 0) {
                altitude = 0;
                status = "Landed";
                velocity.set(0, 0);
                gameManager.messageBox.showEvent("Landed safely.");
            }
        }
    }


}

// Lunchbox/food object class
class Lunchbox extends Thing implements Interactable {
    color boxColor; // Color of lunchbox
    float price; // Price to buy
    float energyValue; // Hunger reduction amount
    boolean consumed = false; // Whether food has been eaten
    String label; // Food type label

    Lunchbox(String label, color boxColor, float posX, int sceneIn, float price, float energyValue) {
        this.boxColor = boxColor;
        this.price = price;
        this.energyValue = energyValue;
        this.label = label;

        this.initialize();
        this.position = new PVector(posX, height*random(0.3, 0.6));
        this.velocity = new PVector(0, 0);
        this.acceleration = new PVector(0, 0);
        this.elasticity = 0.5;
        this.grabbable = true;
        this.occupied = false;
        this.sceneIn = sceneIn;
        this.friction = 0.9;
        this.groundHeightOffset = 26;
        this.hasPhysics = true; // Lunchbox has physics
    }

    // Display the lunchbox - REQUIRED by abstract class Thing
    void display() {
        if (this.show && !consumed) {
            textAlign(CENTER);
            strokeWeight(2);
            // Draw lunchbox body
            fill(boxColor);
            rect(this.position.x - 40, this.position.y - 15, 80, 50, 10);

            // Draw lunchbox latch
            fill(100);
            rect(this.position.x - 10, this.position.y - 20, 20, 10, 5);

            if (this.price > 0) {
              // Draw price tag
              fill(255);
              stroke(0);
              strokeWeight(1);
              rect(this.position.x - 25, this.position.y - 50, 50, 25, 5);
              
              // Draw price text
              fill(0);
              textSize(14);
              text("$" + nf(price, 0, 0), this.position.x, this.position.y - 34);
            }
            
            fill(0);
            // Draw energy value
            textSize(12);
            text("-" + nf(energyValue, 0, 0) + " hunger", this.position.x, this.position.y + 24);

            // Draw label
            fill(0);
            textSize(16);
            text(label, this.position.x, this.position.y + 5);

            // Reset text alignment
            textAlign(LEFT);
        }
    }

    // Interactable interface implementation
    void onGrab(Human human) {
      if (human instanceof GameHuman) {
        GameHuman gameHuman = (GameHuman) human;
        // When grabbed, show info about the lunchbox
        gameManager.messageBox.showEvent("Lunchbox '" + label + "' grabbed by " + gameHuman.firstName);
        gameManager.messageBox.showEvent("Price: $" + price + ", Hunger reduction: " + energyValue);
        gameManager.messageBox.showEvent("Hold SHIFT while grabbing to eat this lunchbox!");
      }
    }

    boolean isGrabbable() {
        return this.grabbable && !this.held && !this.occupied && !this.consumed;
    }

    void onRelease() {
    }

    
    // Add onInteract method
    void onInteract(Human human) {
      if (human instanceof GameHuman) {
        GameHuman gameHuman = (GameHuman) human;
        // Eat the lunchbox when SHIFT is pressed
        if (!consumed && gameHuman.money >= price) {
            // Consume the food
            gameHuman.eatFood(this);

            // Make sure hunger doesn't go below 0
            if (gameHuman.hunger < 0) {
                gameHuman.hunger = 0;
            }

            // Hide the food
            consumed = true;
            this.hide();

            gameManager.messageBox.showEvent(gameHuman.firstName + " ate " + label + "! Hunger: " + nf(gameHuman.hunger, 0, 1));
            
            // Release after eating
            if (gameHuman.grabObj == this) {
                gameHuman.release();
            }
        } else if (gameHuman.money < price) {
            gameManager.messageBox.showAlert("Not enough money! Need $" + price + ", but only have $" + nf(gameHuman.money, 0, 2));
        }
      }
    }
  }


// Cash bag with passcode protection
class CashBag extends Thing implements Interactable {
    color bagColor; // Color of cash bag
    float cashAmount; // Amount of money inside
    String passcode; // Passcode to unlock
    boolean unlocked = false; // Whether bag has been unlocked
    int wrongAttempts = 0; // Number of wrong passcode attempts
    int cooldownOnWrongAttempts = 3; // Trigger cooldown on this many wrong attempts
    int lastAttemptTime = 0; // Time of last attempt
    int cooldownTime = 2000; // 2 seconds cooldown after wrong attempt
    String feedbackMessage = ""; // Message to display
    int feedbackTime = 0; // Time feedback message was shown
    String hint = ""; // Hint to show in password box
    Human lastGrabbedHuman = null;
    
    // Input box for passcode entry
    InputBox passcodeInputBox;

    CashBag(color bagColor, float posX, int sceneIn, float cashAmount, String passcode, String hint) {
        this.bagColor = bagColor;
        this.cashAmount = cashAmount;
        this.passcode = passcode;
        this.hint = hint;
        
        this.initialize();
        this.position = new PVector(posX, height*0.4);
        this.velocity = new PVector(0, 0);
        this.acceleration = new PVector(0, 0);
        this.elasticity = 0.3;
        this.grabbable = false;
        this.occupied = false;
        this.sceneIn = sceneIn;
        this.friction = 0.85;
        this.groundHeightOffset = 36;
        
        // Create input box for passcode entry
        float boxWidth = 400;
        float boxHeight = 200;
        passcodeInputBox = new InputBox(
            width/2 - boxWidth/2, 
            height/2 - boxHeight/2,
            boxWidth,
            boxHeight,
            "ENTER PASSCODE",
            hint
        );
        passcodeInputBox.setMaxLength(40);
        passcodeInputBox.setPasswordMode(true);     
        
        // Customize the input box appearance
        passcodeInputBox.setColors(
            color(255),                    // bgColor
            bagColor,           // borderColor
            color(0),                     // textColor
            color(100, 100, 100)          // hintColor
        );
    }

    // Display the cash bag - REQUIRED by abstract class Thing
    void display() {
        if (this.show && !unlocked) {
            // Draw cash bag
            fill(bagColor);
            stroke(0);
            strokeWeight(2);

            // Bag body
            rect(this.position.x - 40, this.position.y - 30, 80, 60, 15);

            // Draw dollar sign pattern
            fill(180, 255, 180);
            textSize(20);
            textAlign(CENTER);
            text("$", this.position.x, this.position.y - 5);

            // Draw amount
            fill(255);
            textSize(20);
            text(nf(cashAmount, 0, 0), this.position.x, this.position.y + 18);

            // Draw locked symbol
            fill(200, 0, 0);
            ellipse(this.position.x + 25, this.position.y - 15, 15, 15);
            fill(255);
            textSize(12);
            text("LOCKED", this.position.x, this.position.y - 35);

            // Draw wrong attempts counter if any
            if (wrongAttempts > 0) {
                fill(255, 100, 100);
                text("Wrong: " + wrongAttempts, this.position.x, this.position.y - 50);
            }

            // Draw feedback message if active
            if (millis() - feedbackTime < 3000 && !feedbackMessage.isEmpty()) {
                fill(255, 100, 100);
                textSize(14);
                text(feedbackMessage, this.position.x, this.position.y - 65);
            }

            // Reset text alignment
            textAlign(LEFT);
        } else if (this.show && unlocked) {
            // Draw opened/empty bag
            fill(150);
            stroke(0);
            strokeWeight(1);

            // Empty bag
            rect(this.position.x - 40, this.position.y - 30, 80, 60, 15);

            // Draw "EMPTY" text
            fill(100);
            textSize(18);
            textAlign(CENTER);
            text("EMPTY", this.position.x, this.position.y);

            // Draw money received message for a few seconds
            if (millis() - feedbackTime < 3000 && feedbackMessage.equals("CORRECT!")) {
                fill(100, 255, 100);
                textSize(14);
                text("+" + cashAmount, this.position.x, this.position.y + 20);
            } else if (millis() - feedbackTime > 5000 && feedbackMessage.equals("CORRECT!")) { this.hide(); // hide if empty for 5 seconds 
            }

            textAlign(LEFT);
        }
    }

    // Interactable interface implementation
    void onGrab(Human human) {
        lastGrabbedHuman = human;
        gameManager.messageBox.showEvent("Grabbed CashBag with " + cashAmount + "! Press SHIFT to unlock.");
    }
    
    void onInteract(Human human) {
        if (!unlocked) {
            // Check cooldown
            if (millis() - lastAttemptTime < cooldownTime && wrongAttempts >= cooldownOnWrongAttempts) {
                int remaining = (cooldownTime - (millis() - lastAttemptTime)) / 1000 + 1;
                feedbackMessage = "Cooldown: " + remaining + "s";
                feedbackTime = millis();
                gameManager.messageBox.showAlert("Try again in " + remaining + " seconds");
                return;
            }
            if (!passcodeInputBox.isVisible()) {
              // Show the input box
              passcodeInputBox.show(
                  // onSubmit callback - called when user presses ENTER
                  () -> {
                      checkPasscode(passcodeInputBox.getText());
                  },
                  // onCancel callback - called when user presses 'DELETE' when empty
                  () -> {
                      gameManager.messageBox.showEvent("Passcode input cancelled");
                      feedbackMessage = "CANCELLED";
                      feedbackTime = millis();
                  }
              );
            }
        
        } else {
            gameManager.messageBox.showEvent("This cash bag is already empty!");
            feedbackMessage = "ALREADY EMPTY";
            feedbackTime = millis();
        }
    }

    boolean isGrabbable() {
      return true;
    }

    void onRelease() {
    }

    // Check if entered passcode is correct
    void checkPasscode(String input) {
      if (lastGrabbedHuman != null && lastGrabbedHuman instanceof GameHuman) {
        GameHuman gameHuman = (GameHuman) lastGrabbedHuman;
        if (input.equals(passcode)) {
            // Correct passcode!
            unlocked = true;
            gameHuman.money += cashAmount;
            feedbackMessage = "CORRECT!";
            feedbackTime = millis();
            wrongAttempts = 0;

            gameManager.messageBox.showEvent("PASSCODE CORRECT! " + gameHuman.firstName + " gained $" + cashAmount);
            gameManager.messageBox.showEvent(gameHuman.firstName + " now has $" + nf(gameHuman.money, 0, 2));

            // Release if human was somehow holding this
            if (gameHuman.grabObj == this) {
                gameHuman.release();
            }
            
            // Hide the input box
            passcodeInputBox.hide();
        } else {
            // Wrong passcode
            wrongAttempts++;
            lastAttemptTime = millis();
            feedbackMessage = "WRONG! Attempts: " + wrongAttempts;
            feedbackTime = millis();

            gameManager.messageBox.showAlert("WRONG PASSCODE! Attempt " + wrongAttempts);
            
            // Clear the input box
            passcodeInputBox.setText("");
            
            gameHuman.release();
            
            // If too many wrong attempts, cooldown
            if (wrongAttempts >= cooldownOnWrongAttempts)  {
                cooldownTime = wrongAttempts * 2000; // Increase cooldown with attempts
                feedbackMessage = "ATTEMPTS EXCEEDED! Wait " + (cooldownTime/1000) + "s";
                passcodeInputBox.hide(); // Hide input box during cooldown
            }
        }
      }
    }

    // Update method to handle input box updates
    void update() {
        super.update();
    }
}

class PreFilledCupboard extends Cupboard {
    ArrayList<Thing> cupboardItems;
    String label = "Cupboard";
    
    PreFilledCupboard(String label, color woodColor, float x, float cupboardHeight, float cupboardWidth, 
           int sceneIn, int sceneDes, Thing[] customThings) {
        super(woodColor, x, cupboardHeight, cupboardWidth, sceneIn, sceneDes);
        this.cupboardItems = new ArrayList<Thing>(Arrays.asList(customThings));
        this.label = label;
        for (int i = 0; i < cupboardItems.size(); i++) {
          gameManager.objects.add(cupboardItems.get(i));
        }
    }
    
    void onGrab(Human human) {};
    void onInteract(Human human) {
        if (!opened) {
            opened = true;
            
            for (Thing item : cupboardItems) {
                if (item != null && (item.sceneIn == this.sceneDes)) {
                    item.sceneIn = this.sceneIn;
                    item.show = true;
                    float angle = random(TWO_PI);
                    float radius = random(100, 150);
                    item.position.x = this.position.x + cos(angle) * radius;
                    item.position.y = this.position.y + sin(angle) * 30;
                    
                    // Give a good toss so it's visible
                    item.velocity.set(random(-10, 10), random(-20, -30));
                    item.held = false;
                    item.rested = false;
                    
                    // Make sure items are drawn after cupboard by reordering in objects list
                    reorderItemsInFront();
                    
                }
            }
        } else {
            gameManager.messageBox.showEvent("Cupboard closed. Collecting surrounding items...");
            
            // Collect nearby items like normal cupboard
            for (Thing obj : gameManager.objects) {
                    Thing item = obj;
                    if (item.sceneIn == this.sceneIn) {
                        float distance = PVector.dist(this.position, item.position);
                        if (distance < 150 && !item.held && item.hasPhysics) {
                          if (!cupboardItems.contains(item)) cupboardItems.add(item);
                            item.sceneIn = this.sceneDes;
                            item.show = false;
                            item.velocity.set(0, 0);
                            item.position.x = this.position.x;
                            item.position.y = this.position.y - 30;
                        }
                    }
            }
            
            this.opened = false;
        }
    }
    
    // Reorder items to be drawn after cupboard in objects list
    void reorderItemsInFront() {
        // Remove cupboard from objects temporarily
        gameManager.objects.remove(this);
        
        // Re-add cupboard FIRST (so it draws first, in background)
        gameManager.objects.add(0, this);
        
        // Now items will be drawn after cupboard
    }
    
    @Override
    void display() {
        if (!show) return;
        strokeWeight(2);
        // Draw cupboard body
        fill(woodColor);
        rect(position.x - cupboardWidth / 2, position.y - cupboardHeight + 36, 
             cupboardWidth, cupboardHeight);
        
        // Draw doors
        fill(lerpColor(woodColor, color(40), 0.2));
        if (opened) {
            // Draw open doors
            quad(position.x - cupboardWidth / 2, position.y - cupboardHeight + 36,
                position.x - cupboardWidth, position.y - cupboardHeight + 26,
                position.x - cupboardWidth, position.y - 20 + 38,
                position.x - cupboardWidth / 2, position.y - 20 + 56);

            quad(position.x + cupboardWidth / 2, position.y - cupboardHeight + 36,
                position.x + cupboardWidth, position.y - cupboardHeight + 26,
                position.x + cupboardWidth, position.y - 20 + 38,
                position.x + cupboardWidth / 2, position.y - 20 + 56);
        } else {
            // Draw closed doors with handles
            rect(position.x - cupboardWidth / 2 + 2, position.y - cupboardHeight + 38, 
                 cupboardWidth / 2 - 4, cupboardHeight - 4);
            rect(position.x + 2, position.y - cupboardHeight + 38, 
                 cupboardWidth / 2 - 4, cupboardHeight - 4);
            
            // Draw handles
            fill(100);
            ellipse(position.x - cupboardWidth/4, 
                    position.y - cupboardHeight/2, 
                    12, 20);
            ellipse(position.x + cupboardWidth/4, 
                    position.y - cupboardHeight/2, 
                    12, 20);
        }
        
        // Draw label
        fill(50);
        textSize(14);
        textAlign(CENTER);
        text(this.label, position.x, position.y - cupboardHeight + 20);
        textAlign(LEFT);
    }
}
