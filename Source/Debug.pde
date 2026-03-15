import java.lang.management.ManagementFactory;
import java.lang.management.OperatingSystemMXBean;
import java.lang.reflect.Method;

class Debug {
    // Which human to track - instance variables 
    Human trackedHuman = null;
    
    // Debug settings - instance variables
    boolean showDebug = false;
    color debugColor = color(0, 255, 0);
    color warningColor = color(255, 255, 0);
    color errorColor = color(255, 0, 0);
    
    // Constructor
    Debug() {
        // Nothing needed here
    }
    
    void toggle() {
        showDebug = !showDebug;
        println("Debug mode: " + (showDebug ? "ON" : "OFF"));
    }
    
    void setDebug(Human human, boolean show) {
      this.trackedHuman = human;
      this.showDebug = show;
    }
    
    void display() {
        if (!showDebug) return;
        
        push();
        
        // Dark semi-transparent background
        fill(0, 0, 0, 200);
        noStroke();
        rect(10, 10, 350, trackedHuman != null ? 480 : 360, 10);
        
        fill(debugColor);
        textSize(14);
        textAlign(LEFT);
        
        int yPos = 30;
        int lineHeight = 20;
        int col2 = 150;
        
        // ===== SYSTEM INFO =====
        fill(debugColor);
        text("=== SYSTEM INFO ===", 20, yPos);
        yPos += lineHeight;
        
        text("Frame:", 20, yPos);
        text(frameCount, 20 + col2, yPos);
        yPos += lineHeight;
        
        text("Millis:", 20, yPos);
        text(millis() + " ms", 20 + col2, yPos);
        yPos += lineHeight;
        
        text("FPS:", 20, yPos);
        text(nf(frameRate, 0, 1), 20 + col2, yPos);
        yPos += lineHeight;
        
        text("Scene:", 20, yPos);
        text(gameManager.window.scene, 20 + col2, yPos);
        yPos += lineHeight + 5;
        
        // ===== OBJECT COUNTS =====
        text("=== OBJECTS ===", 20, yPos);
        yPos += lineHeight;
        
        text("Total Things:", 20, yPos);
        text(gameManager.objects.size(), 20 + col2, yPos);
        yPos += lineHeight;
        
        text("Active in scene:", 20, yPos);
        int activeInScene = 0;
        for (Thing t : gameManager.objects) {
            if (t.show && t.sceneIn == gameManager.window.scene) activeInScene++;
        }
        text(activeInScene, 20 + col2, yPos);
        yPos += lineHeight + 5;
        
        // ===== TRACKED HUMAN INFO =====
        if (trackedHuman != null) {
            text("=== TRACKED HUMAN: " + trackedHuman.name + " ===", 20, yPos);
            yPos += lineHeight;
            
            // Position
            text("Position:", 20, yPos);
            text("(" + nf(trackedHuman.position.x, 0, 1) + 
                 ", " + nf(trackedHuman.position.y, 0, 1) + ")", 
                 20 + col2, yPos);
            yPos += lineHeight;
            
            // Velocity
            text("Velocity:", 20, yPos);
            text("(" + nf(trackedHuman.velocity.x, 0, 1) + 
                 ", " + nf(trackedHuman.velocity.y, 0, 1) + ")", 
                 20 + col2, yPos);
            yPos += lineHeight;
            
            // Acceleration
            text("Acceleration:", 20, yPos);
            text("(" + nf(trackedHuman.acceleration.x, 0, 2) + 
                 ", " + nf(trackedHuman.acceleration.y, 0, 2) + ")", 
                 20 + col2, yPos);
            yPos += lineHeight;
            
            // State
            text("State:", 20, yPos);
            String state = "";
            if (trackedHuman.rested) state = "RESTING";
            else if (trackedHuman.held) state = "HELD";
            else if (trackedHuman.position.y != height*gameManager.window.getGroundHeightAt(trackedHuman.position.x) - trackedHuman.groundHeightOffset) state = "JUMPING"; 
            // MAX_VELOCITY because human is constantly accelerating downwards due to gravity
            else if (trackedHuman.velocity.x != 0) state = "MOVING";
            else state = "IDLE";
            text(state, 20 + col2, yPos);
            yPos += lineHeight;
            
            // Grabbed object
            fill(trackedHuman.grabbed ? warningColor : debugColor);
            text("Grabbed:", 20, yPos);
            if (trackedHuman.grabbed && trackedHuman.grabObj != null) {
                String objInfo = trackedHuman.grabObj.getClass().getSimpleName();
                if (trackedHuman.grabObj instanceof CashBag) {
                    CashBag cb = (CashBag) trackedHuman.grabObj;
                    objInfo += " $" + cb.cashAmount;
                } else if (trackedHuman.grabObj instanceof Lunchbox) {
                    Lunchbox lb = (Lunchbox) trackedHuman.grabObj;
                    objInfo += " " + lb.label;
                }
                text(objInfo, 20 + col2, yPos);
            } else {
                text("None", 20 + col2, yPos);
            }
            yPos += lineHeight;
            
            // If GameHuman, show stats
            if (trackedHuman instanceof GameHuman) {
                GameHuman gh = (GameHuman) trackedHuman;
                
                text("Hunger:", 20, yPos);
                float hungerPercent = gh.hunger;
                if (hungerPercent > 75) fill(errorColor);
                else if (hungerPercent > 50) fill(warningColor);
                else fill(debugColor);
                text(nf(gh.hunger, 0, 1) + "%", 20 + col2, yPos);
                yPos += lineHeight;
                
                fill(debugColor);
                text("Money:", 20, yPos);
                text("$" + nf(gh.money, 0, 2), 20 + col2, yPos);
                yPos += lineHeight;
            }
            yPos += 5;
            
            // ===== CLOSEST OBJECT =====
            text("=== CLOSEST OBJECT (within grabRange - " + nf(trackedHuman.grabRange, 0, 0) + "px) ===", 20, yPos);
            yPos += lineHeight;
            
            Thing closest = null;
            ArrayList<Thing> nearby = trackedHuman.getClosestObjects(gameManager.objects, trackedHuman.grabRange);
            closest = nearby.size() > 0 ? nearby.get(0) : null;

            if (closest != null) {
                String typeName = closest.getClass().getSimpleName();
                fill(debugColor);
                text("Type:", 20, yPos);
                text(typeName, 20 + col2, yPos);
                yPos += lineHeight;
                
                text("Distance:", 20, yPos);
                text(nf(PVector.dist(trackedHuman.position, closest.position), 0, 1) + " px", 20 + col2, yPos);
                yPos += lineHeight;
                
                text("Position:", 20, yPos);
                text("(" + nf(closest.position.x, 0, 1) + 
                     ", " + nf(closest.position.y, 0, 1) + ")", 
                     20 + col2, yPos);
                yPos += lineHeight;
                
                // Show if grabbable/interactable
                if (closest instanceof Interactable) {
                    text("Interactable:", 20, yPos);
                    text("YES", 20 + col2, yPos);
                    yPos += lineHeight;
                    
                    text("Grabbable:", 20, yPos);
                    text(((Interactable)closest).isGrabbable() ? "YES" : "NO", 
                         20 + col2, yPos);
                    yPos += lineHeight;
                }
            } else {
                text("None within range", 20, yPos);
                yPos += lineHeight;
            }
        } else {
            fill(warningColor);
            text("=== NO HUMAN TRACKED ===", 20, yPos);
            yPos += lineHeight;
            text("Set debug.trackedHuman in GameInit!", 20, yPos);
        }
        
        yPos = height - 40;
        fill(debugColor);
        textSize(12);
        text("Tracked: " + 
             (trackedHuman != null ? trackedHuman.name : "NONE"), 20, yPos);
        
        pop();
    }
    
    void drawVisualHelpers() {  
        if (!showDebug || trackedHuman == null) return;
        
        push();
        noFill();
        
        // Draw grab range
        stroke(0, 255, 0, 100);
        strokeWeight(2);
        ellipse(trackedHuman.position.x, trackedHuman.position.y, 
                trackedHuman.grabRange * 2, trackedHuman.grabRange * 2);
        
        // Draw detection range
        stroke(255, 255, 0, 100);
        ellipse(trackedHuman.position.x, trackedHuman.position.y, trackedHuman.grabRange * 2, trackedHuman.grabRange * 2);
        
        // Draw line to closest object
        Thing closest = null;
        ArrayList<Thing> nearby = trackedHuman.getClosestObjects(gameManager.objects, trackedHuman.grabRange);
        closest = nearby.size() > 0 ? nearby.get(0) : null;

        if (closest != null) {
            stroke(255, 255, 0, 200);
            strokeWeight(1);
            line(trackedHuman.position.x, trackedHuman.position.y, 
                 closest.position.x, closest.position.y);
        }
        
        pop();

        gameManager.window.drawKeyframeMarkers();
    }

    void printSystemDump() {
        println("\n========== COMPLETE SYSTEM DUMP ==========");
        
        // ===== SYSTEM PROPERTIES =====
        println("\n--- SYSTEM PROPERTIES ---");
        java.util.Properties props = System.getProperties();
        java.util.Enumeration keys = props.propertyNames();
        while (keys.hasMoreElements()) {
            String key = (String) keys.nextElement();
            String value = props.getProperty(key);
            println(key + " = " + value);
        }
        
        // ===== RUNTIME INFO =====
        println("\n--- RUNTIME INFO ---");
        Runtime rt = Runtime.getRuntime();
        println("availableProcessors = " + rt.availableProcessors());
        println("freeMemory = " + rt.freeMemory() + " bytes (" + (rt.freeMemory()/1024/1024) + " MB)");
        println("totalMemory = " + rt.totalMemory() + " bytes (" + (rt.totalMemory()/1024/1024) + " MB)");
        println("maxMemory = " + rt.maxMemory() + " bytes (" + (rt.maxMemory()/1024/1024) + " MB)");
        println("usedMemory = " + (rt.totalMemory() - rt.freeMemory()) + " bytes");
        
        // ===== PROCESSING INFO =====
        println("\n--- PROCESSING INFO ---");
        println("sketchPath = " + sketchPath());
        println("dataPath(\"\") = " + dataPath(""));
        println("frameCount = " + frameCount);
        println("frameRate = " + frameRate);
        println("focused = " + focused);
        println("key = " + key);
        println("keyCode = " + keyCode);
        println("keyPressed = " + keyPressed);
        println("mouseX = " + mouseX);
        println("mouseY = " + mouseY);
        println("pmouseX = " + pmouseX);
        println("pmouseY = " + pmouseY);
        println("mouseButton = " + mouseButton);
        println("mousePressed = " + mousePressed);
        println("width = " + width);
        println("height = " + height);
        println("pixelWidth = " + pixelWidth);
        println("pixelHeight = " + pixelHeight);
        println("displayWidth = " + displayWidth);
        println("displayHeight = " + displayHeight);
        
        // ===== DISPLAY INFO =====
        println("\n--- DISPLAY INFO ---");
        println("displayDensity() = " + displayDensity());
        println("pixelDensity = " + pixelDensity);
        
        // ===== PLATFORM INFO =====
        println("\n--- PLATFORM INFO ---");
        println("platform = " + platform);
        println("Platform identifiers:");
        println("  WINDOWS = " + WINDOWS);
        println("  MACOS = " + MACOS);
        println("  LINUX = " + LINUX);
        println("  OTHER = " + OTHER);
        if (platform == WINDOWS) println("  Current: WINDOWS");
        else if (platform == MACOS) println("  Current: MACOS");
        else if (platform == LINUX) println("  Current: LINUX");
        else println("  Current: OTHER");
        
        // ===== ENVIRONMENT VARIABLES =====
        println("\n--- ENVIRONMENT VARIABLES (selected) ---");
        java.util.Map<String, String> env = System.getenv();
        String[] importantEnvVars = {"PATH", "HOME", "USER", "USERNAME", "OS", "JAVA_HOME"};
        for (String vari : importantEnvVars) {
            String value = env.get(vari);
            if (value != null) {
                println(vari + " = " + value);
            }
        }
        
        // ===== TIME INFO =====
        println("\n--- TIME INFO ---");
        println("millis() = " + millis() + " ms");
        println("second() = " + second());
        println("minute() = " + minute());
        println("hour() = " + hour());
        println("day() = " + day());
        println("month() = " + month());
        println("year() = " + year());
        println("timestamp = " + year() + "-" + month() + "-" + day() + " " + hour() + ":" + minute() + ":" + second());
        
        // ===== THREAD INFO =====
        println("\n--- THREAD INFO ---");
        Thread currentThread = Thread.currentThread();
        println("currentThread = " + currentThread.getName());
        println("thread ID = " + currentThread.getId());
        println("thread priority = " + currentThread.getPriority());
        println("thread state = " + currentThread.getState());
        println("thread group = " + currentThread.getThreadGroup().getName());
        
        // ===== MEMORY INFO (detailed) =====
        println("\n--- MEMORY INFO (detailed) ---");
        java.lang.management.MemoryMXBean memoryBean = java.lang.management.ManagementFactory.getMemoryMXBean();
        java.lang.management.MemoryUsage heapUsage = memoryBean.getHeapMemoryUsage();
        java.lang.management.MemoryUsage nonHeapUsage = memoryBean.getNonHeapMemoryUsage();
        
        println("HEAP MEMORY:");
        println("  init = " + heapUsage.getInit()/1024/1024 + " MB");
        println("  used = " + heapUsage.getUsed()/1024/1024 + " MB");
        println("  committed = " + heapUsage.getCommitted()/1024/1024 + " MB");
        println("  max = " + heapUsage.getMax()/1024/1024 + " MB");
        
        println("NON-HEAP MEMORY:");
        println("  init = " + nonHeapUsage.getInit()/1024/1024 + " MB");
        println("  used = " + nonHeapUsage.getUsed()/1024/1024 + " MB");
        println("  committed = " + nonHeapUsage.getCommitted()/1024/1024 + " MB");
        println("  max = " + nonHeapUsage.getMax()/1024/1024 + " MB");
        
        // ===== CLASS LOADING INFO =====
        println("\n--- CLASS LOADING INFO ---");
        java.lang.management.ClassLoadingMXBean classBean = java.lang.management.ManagementFactory.getClassLoadingMXBean();
        println("loadedClassCount = " + classBean.getLoadedClassCount());
        println("totalLoadedClassCount = " + classBean.getTotalLoadedClassCount());
        println("unloadedClassCount = " + classBean.getUnloadedClassCount());
        
        // ===== OPERATING SYSTEM INFO =====
        println("\n--- OS INFO (detailed) ---");
        java.lang.management.OperatingSystemMXBean osBean = java.lang.management.ManagementFactory.getOperatingSystemMXBean();
        println("os.arch = " + System.getProperty("os.arch"));
        println("os.name = " + System.getProperty("os.name"));
        println("os.version = " + System.getProperty("os.version"));
        println("systemLoadAverage = " + osBean.getSystemLoadAverage());
        
        // Try to get more OS info if available (may not work on all platforms)
        try {
          Class<?> sunClass = Class.forName("com.sun.management.OperatingSystemMXBean");
          
          if (sunClass.isInstance(osBean)) {
            println("--- Sun/Oracle Specific Stats ---");
            
            // 2. Helper to invoke methods by name safely
            printStat(osBean, sunClass, "Total Physical Memory", "getTotalPhysicalMemorySize");
            printStat(osBean, sunClass, "Free Physical Memory", "getFreePhysicalMemorySize");
            printStat(osBean, sunClass, "Total Swap Space", "getTotalSwapSpaceSize");
            printStat(osBean, sunClass, "Free Swap Space", "getFreeSwapSpaceSize");
            printStat(osBean, sunClass, "Committed Virtual Memory", "getCommittedVirtualMemorySize");
            
            // 3. CPU loads (usually returns a double between 0.0 and 1.0)
            printRawStat(osBean, sunClass, "Process CPU Load", "getProcessCpuLoad");
            printRawStat(osBean, sunClass, "System CPU Load", "getSystemCpuLoad");

          }
        } catch (Exception e) {
            // The class doesn't exist on this JVM (e.g., IBM J9 or some restricted environments)
            println("Sun-specific MXBean not available.");
        }
        
        // ===== FILE SYSTEM INFO =====
        println("\n--- FILE SYSTEM INFO ---");
        java.io.File[] roots = java.io.File.listRoots();
        for (java.io.File root : roots) {
            println("root = " + root.getPath());
            println("  total space = " + root.getTotalSpace()/1024/1024/1024 + " GB");
            println("  free space = " + root.getFreeSpace()/1024/1024/1024 + " GB");
            println("  usable space = " + root.getUsableSpace()/1024/1024/1024 + " GB");
        }
        
        // ===== NETWORK INFO =====
        println("\n--- NETWORK INFO ---");
        try {
            java.net.InetAddress localhost = java.net.InetAddress.getLocalHost();
            println("hostname = " + localhost.getHostName());
            println("hostAddress = " + localhost.getHostAddress());
            println("canonicalHostName = " + localhost.getCanonicalHostName());
            
            java.net.NetworkInterface.getNetworkInterfaces().asIterator().forEachRemaining(ni -> {
                try {
                    if (!ni.isLoopback()) {
                        println("network interface = " + ni.getName());
                        println("  display name = " + ni.getDisplayName());
                        println("  hardware address = " + java.util.Arrays.toString(ni.getHardwareAddress()));
                        println("  MTU = " + ni.getMTU());
                    }
                } catch (Exception e) {}
            });
        } catch (Exception e) {
            println("Network info unavailable: " + e.getMessage());
        }
        
        // ===== SECURITY INFO =====
        /*println("\n--- SECURITY INFO ---");
        java.security.Provider[] providers = java.security.Security.getProviders();
        for (int p = 0; p < providers.length; p++) {
            java.security.Provider provider = providers[p];
            println("provider " + p + " = " + provider.getName());
            
            java.util.Enumeration<Object> providerKeys = provider.keys();
            while (providerKeys.hasMoreElements()) {
                String keyName = (String) providerKeys.nextElement();
                println("  " + keyName + " = " + provider.getProperty(keyName));
            }
        }*/
        
        // ===== LOCALE INFO =====
        println("\n--- LOCALE INFO ---");
        java.util.Locale defaultLocale = java.util.Locale.getDefault();
        println("default locale = " + defaultLocale);
        println("language = " + defaultLocale.getLanguage());
        println("country = " + defaultLocale.getCountry());
        println("display name = " + defaultLocale.getDisplayName());
        println("script = " + defaultLocale.getScript());
        println("variant = " + defaultLocale.getVariant());
        
        // ===== TIMEZONE INFO =====
        println("\n--- TIMEZONE INFO ---");
        java.util.TimeZone tz = java.util.TimeZone.getDefault();
        println("timezone = " + tz.getID());
        println("display name = " + tz.getDisplayName());
        println("offset = " + tz.getRawOffset()/3600000 + " hours");
        println("uses DST = " + tz.useDaylightTime());
        
        println("\n========== END DUMP ==========");
    }
    // Helper for Memory stats (converts to MB)
    private void printStat(Object bean, Class<?> clazz, String label, String methodName) throws Exception {
        Method method = clazz.getMethod(methodName);
        long value = (Long) method.invoke(bean);
        println(label + " = " + (value / 1024 / 1024) + " MB");
    }
    
    // Helper for CPU stats (raw double)
    private void printRawStat(Object bean, Class<?> clazz, String label, String methodName) throws Exception {
        Method method = clazz.getMethod(methodName);
        Object value = method.invoke(bean);
        println(label + " = " + value);
    }
}
