class Tile {
  public final color barrenColor = color(0,0,1);
  public final color fertileColor = color(0,0,0.2);
  public final color blackColor = color(0,1,0);
  public final color waterColor = color(0,0,0);
  public final float FOOD_GROWTH_RATE = 1.0;
  
  private float fertility;      // how likely are creatues to reproduce on this tile?
  private float foodLevel;      // the amount of food left
  private final float maxGrowthLevel = 1.0;      // the maximum amount of resources
  private int posX;             // temp position X
  private int posY;             // temp position Y
  
  public float climateType;     // climates types are?
  public float foodType;        // food types are?
  
  // initializes a new tile at a given x and y position with a starting amount of food and a type
  public Tile(int x, int y, float f, float food, float type) {
    posX = x;
    posY = y;
    fertility = max(0,f);
    foodLevel = max(0,food);
    climateType = foodType = type;
  }
  public float getFertility() {
    return fertility;
  }
  public float getFoodLevel() {
    return foodLevel;
  }
  public void setFertility(float f) {
    fertility = f;
  }
  public void setFoodLevel(float f) {
    foodLevel = f;
  }
  public void drawTile(float scaleFactor, boolean showEnergy) {
    // draw border
    stroke(0, 0, 0, 1);
    strokeWeight(2);
    
    // draw tile
    color landColor = getColor();
    fill(landColor);
    rect(posX * scaleFactor, posY * scaleFactor, scaleFactor, scaleFactor);
    
    // display information text if moused over
    if (showEnergy) {
      if (brightness(landColor) >= 0.7) {
        // color text black
        fill(0, 0, 0, 1);
      } else {
        // color text white
        fill(0, 0, 1, 1);
      }
      
      // set text properties
      textAlign(CENTER);
      textFont(font, 21);
      
      // draw text
      text(nf(100 * foodLevel, 0, 2) + " yums", (posX + 0.5) * scaleFactor,(posY + 0.3) * scaleFactor);
      text("Clim: " + nf(climateType, 0, 2), (posX + 0.5) * scaleFactor, (posY + 0.6) * scaleFactor);
      text("Food: " + nf(foodType, 0, 2), (posX + 0.5) * scaleFactor, (posY + 0.9) * scaleFactor);
    }
  }
  
  public void iterate(double timeStep, float growableTime) {
    if (fertility > 1) {
      foodLevel = 0;
    } else {
      if (growableTime > 0) {
        if (foodLevel < maxGrowthLevel) {
          // determine how much food this tile gains each iteration
          double foodGrowthAmount = (maxGrowthLevel - foodLevel) * fertility * FOOD_GROWTH_RATE * timeStep * growableTime;
          // and then add that to the tile
          addFood(foodGrowthAmount, climateType);
        }
      } else {
        foodLevel += maxGrowthLevel * foodLevel * FOOD_GROWTH_RATE * timeStep * growableTime;
      }
    }
    foodLevel = max(foodLevel, 0);
  }
  
  public void addFood(double amount, double addedFoodType) {
    foodLevel += amount;
    if (foodLevel > 0) {
      // We're adding new plant growth, so we gotta "mix" the colors of the tile.
      foodType += (addedFoodType - foodType) * (amount / foodLevel);
    }
  }
  
  public color getColor() {
    color foodColor = color(foodType, 1, 1);
    if(fertility > 1){
      return waterColor;
    }else if(foodLevel < maxGrowthLevel){
      return interColorFixedHue(interColor(barrenColor,fertileColor,fertility),foodColor,foodLevel/maxGrowthLevel,hue(foodColor));
    }else{
      return interColorFixedHue(foodColor,blackColor,1.0-maxGrowthLevel/foodLevel,hue(foodColor));
    }
  }
  public color interColor(color a, color b, float x){
    float hue = inter(hue(a),hue(b),x);
    float sat = inter(saturation(a),saturation(b),x);
    float bri = inter(brightness(a),brightness(b),x); // I know it's dumb to do interpolation with HSL but oh well
    return color(hue,sat,bri);
  }
  public color interColorFixedHue(color a, color b, float x, float hue){
    float satB = saturation(b);
    if(brightness(b) == 0){ // I want black to be calculated as 100% saturation
      satB = 1;
    }
    float sat = inter(saturation(a),satB,x);
    float bri = inter(brightness(a),brightness(b),x); // I know it's dumb to do interpolation with HSL but oh well
    return color(hue,sat,bri);
  }
  public float inter(float a, float b, float x){
    return a + (b-a)*x;
  }
}