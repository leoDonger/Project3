 Joint[] rightjoints = new Joint[4];
 Joint[] leftjoints = new Joint[4];
 Joint[] bodys = new Joint[4];
 Joint[] rightLegJoints = new Joint[4];
 Joint[] leftLegJoints = new Joint[4];
 Circle[] obstacles = new Circle[2];
 JointSystem rightArm;
 JointSystem leftArm;
 JointSystem body;
 JointSystem rightLeg;
 JointSystem leftLeg;
 JointSystem[] systems = new JointSystem[5];
 JointSystem[] temp = new JointSystem[5];
 Camera camera;
 boolean paused = false;
 boolean use_acc_cap = false;
 boolean use_left = false;
 boolean walking = false;
 boolean limit = false;
 float acc_cap = 0.05;
 Vec2 leftArmGoal;
 Vec2 rightArmGoal;
 Vec2 tempLeftArmGoal = new Vec2(0, 960);
 Vec2 tempRightArmGoal = new Vec2(1280, 960);


//Root


void setupSystem(){
  Vec2 root = new Vec2(1280/2,960/2+45+120+140+30-200);
  bodys[3] = new Joint(30, 0, 0.2, -0.2);
  bodys[2] = new Joint(140, 0, 0.2, -0.2);
  bodys[1] = new Joint(120, 0, 0, 0);
  bodys[0] = new Joint(45, PI+PI/2, PI+PI/2, PI+PI/2);
  body = new JointSystem(bodys, root);
  
  rightjoints[0] = new Joint(30, 0.3, PI/4, 0);
  rightjoints[1] = new Joint(100, 0.3, PI/4, -PI/2);
  rightjoints[2] = new Joint(80, 0.3, TWO_PI, -TWO_PI);
  rightjoints[3] = new Joint(45, 0.3, PI/2, -PI/2);
  rightArm = new JointSystem(rightjoints, body.joints[body.num_of_joints-2].end_point.plus(new Vec2(armW/2, 0)));

  leftjoints[0] = new Joint(30, -0.3 + PI, PI, PI-(PI/4));
  // leftjoints[0] = new Joint(30, -0.3, PI, -(PI + PI/4));
  leftjoints[1] = new Joint(100, 0, PI/4, -PI/2);
  leftjoints[2] = new Joint(80, 0, TWO_PI, -TWO_PI);
  leftjoints[3] = new Joint(45, 0, PI/2, -PI/2);
  leftArm = new JointSystem(leftjoints,  body.joints[body.num_of_joints-2].end_point.minus(new Vec2(armW/2, 0)));

  rightLegJoints[0] = new Joint(30, 0.1, PI/2, 0);
  rightLegJoints[1] = new Joint(140, 0.1, TWO_PI, -TWO_PI);
  rightLegJoints[2] = new Joint(120, 0.1, TWO_PI, -TWO_PI);
  rightLegJoints[3] = new Joint(45, 0.1, PI/2, -PI/2);
  rightLeg = new JointSystem(rightLegJoints, body.joints[0].start_point.plus(new Vec2(armW/2, 0)));

  leftLegJoints[0] = new Joint(30, -0.1 + PI, PI, PI/2);
  leftLegJoints[1] = new Joint(140, -0.1, TWO_PI, -TWO_PI);
  leftLegJoints[2] = new Joint(120, -0.1, TWO_PI, -TWO_PI);
  leftLegJoints[3] = new Joint(45, -0.1, PI/2, -PI/2);
  leftLeg = new JointSystem(leftLegJoints, body.joints[0].start_point.minus(new Vec2(armW/2, 0)));

  systems[0] = body;
  systems[1] = rightArm;
  systems[2] = leftArm;
  systems[3] = rightLeg;
  systems[4] = leftLeg;
}

PShape b;
PImage ball;
void setup(){
  size(1280,960,P3D);
  surface.setTitle("Inverse Kinematics");
  ball = loadImage("Img/ball.jpg");
  camera = new Camera();
  camera.position = new PVector(719.04254, 117.900024, 545.1439);
  camera.theta = 0.131;
  camera.phi = -0.6536;
  b = createShape(SPHERE, 30);
  b.setTexture(ball);
  obstacles[0] = new Circle(new Vec2(900, 400), 30);
  obstacles[1] = new Circle(new Vec2(550, 400), 30);

  setupSystem();  
}


void solve(){
  if (!use_left){
    rightArmGoal = new Vec2(mouseX, mouseY);
    body.ik(rightArmGoal);
    rightArm.ik(rightArmGoal);
    rightArm.attach(body, body.num_of_joints-2, false, false);
    leftArm.ik(tempLeftArmGoal);
    leftArm.attach(body, body.num_of_joints-2, false, true);
  }else{
    leftArmGoal = new Vec2(mouseX, mouseY);
    body.ik(leftArmGoal);
    rightArm.ik(tempRightArmGoal);
    rightArm.attach(body, body.num_of_joints-2, false, false);
    leftArm.ik(leftArmGoal);
    leftArm.attach(body, body.num_of_joints-2, false, true);
  }

  if (walking){
    Vec2 toRight = new Vec2(1, 0);
    body.root.add(toRight);
  }
  rightLeg.ik(rightLeg.closest_ground());
  rightLeg.attach(body, -1, true, false);
  leftLeg.ik(leftLeg.closest_ground());
  leftLeg.attach(body, -1, true, true);
}


void fk(){
  body.fk();
  rightArm.fk();
  leftArm.fk();
  rightLeg.fk();
  leftLeg.fk();
}

float armW = 20;
void draw(){
  background(255, 255, 255);
  camera.Update(1.0 / frameRate);
  if(paused){
    // fk();
    solve();
  }
  
  body.draw();
  rightArm.draw();
  leftArm.draw();
  rightLeg.draw();
  leftLeg.draw();
  
  // obstacles[0].display();

  for (Circle obstacle: obstacles){
    pushMatrix();
    noStroke();
    // translate(300.77, 320, -2570);
    translate(obstacle.center.x, obstacle.center.y);
    rotateX(frameCount * 0.01); 
    rotateY(frameCount * 0.01); 
    // texture(ball);
    shape(b);
    // sphere(obstacle.radius * scene_scale);
    popMatrix();
  }

  ambient(250, 100, 100);
 // specular(120, 120, 180);
  ambientLight(40, 20,40);
  lightSpecular(255, 215, 215);
  directionalLight(185, 195, 255, -1, 1.25, -1);
  shininess(255);
}

void keyPressed()
{
if (key == ' ') {
  paused = !paused;
}else if(key == 'n' || key == 'N'){
 use_acc_cap = !use_acc_cap;
   if (use_acc_cap){
     println("acc cap applied");
     acc_cap = 0.05;
   }else{
     println("acc cap stopped");
     acc_cap = 1;
   }
 }else if(key == 't' || key == 'T'){
  use_left = !use_left;
   if (use_left){
     println("using left arm");
     tempRightArmGoal = rightArm.endPoint;
   }else{
     println("using right arm");
     tempLeftArmGoal = leftArm.endPoint;
   }
 }else if(key == 'k' || key == 'K'){
   walking = !walking;
   if (walking){
     println("try walking");
   }else{
     println("stop walking");
   }
 }else if(key == 'l' || key == 'L'){
    println("remove joint limit");
    for (JointSystem js: systems){
      for (Joint j:js.joints){
        j.positive_joint_limit = TWO_PI;
        j.negative_joint_limit = -TWO_PI;
      }
    }
 }else if(key == 'r' || key == 'R'){
    println("Resume system");
    setupSystem();
 }
camera.HandleKeyPressed();
}

void keyReleased()
{
camera.HandleKeyReleased();
}

void mouseDragged() {
  obstacles[0].center = new Vec2(mouseX, mouseY);
}
