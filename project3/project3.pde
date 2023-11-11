
class Joint{
  float length;
  // float width;
  float angle;
  Vec2 start_point;
  Vec2 end_point;
  float positive_joint_limit;
  float negative_joint_limit;
  float angleDiff;
  Vec2 top_left, top_right, bottom_left, bottom_right;

  Joint(float l, float a, float pjl, float njl){
    length = l;
    angle = a;
    positive_joint_limit = pjl;
    negative_joint_limit = njl;
  }

  void ik(Vec2 goal, Vec2 endPoint, boolean colliding){
    Vec2 startToGoal = goal.minus(start_point);
    Vec2 startToEndEffector = endPoint.minus(start_point);
    float dotProd = dot(startToGoal.normalized(),startToEndEffector.normalized());
    dotProd = clamp(dotProd,-1,1);

    if (colliding){
      angleDiff *= 0.5;
    }else{
      angleDiff = acos(dotProd);
    }

    boolean direction = cross(startToGoal,startToEndEffector) < 0;
    if (direction)
      angle += angleDiff * acc_cap;
    else
      angle -= angleDiff * acc_cap;
    
    angle = constrain(angle, negative_joint_limit, positive_joint_limit);
  }

  void re_root(){

  }

}

class JointSystem{
  int num_of_joints;
  Joint[] joints;
  float[] angles;
  Vec2 root;
  Vec2 endPoint;

  JointSystem(Joint[] a, Vec2 r){
    num_of_joints = a.length;
    joints = a;
    angles = new float[num_of_joints];
    root = r;
    fk();
  }

  void fk(){
    for(int i = 0; i < num_of_joints; i++){
      if (i == 0){
        joints[i].start_point = root;
        angles[i] = joints[i].angle; 
      }else{
        joints[i].start_point = joints[i-1].end_point;
        angles[i] = joints[i].angle + angles[i-1];
      }

      joints[i].end_point = new Vec2(cos(angles[i])*joints[i].length,sin(angles[i])*joints[i].length).plus(joints[i].start_point); 
    }
    endPoint = joints[num_of_joints-1].end_point;
  }

  void ik(Vec2 goal){
    for(int j = num_of_joints-1; j >= 0; j--){
      float old_angle = joints[j].angle;
      int collision_factor = 0;
      boolean colliding = false;
      do{
        joints[j].angle = old_angle;
        joints[j].ik(goal, endPoint, colliding);
        colliding = true;
        collision_factor++;
        fk();
        if (collision_factor > 100) break;
      } while (colliding_detection());
      if (collision_factor > 100){
        // println("I tried");
        joints[j].angle = old_angle;
      }
    }

    
  }

  boolean colliding_detection(){
      for (Joint j:joints){
        float angle = j.angle;
        float length = j.length;
        Vec2 start_point = j.start_point;
        Vec2 end_point = j.end_point;

        float new_angle = -(PI/2 - angle);
        float x1 = cos(new_angle) * (armW /2);
        float y1 = sin(new_angle) * (armW /2);
        Vec2 width_diff = new Vec2(x1, y1);

        Vec2 top_left = start_point.plus(width_diff);
        Vec2 top_right = end_point.plus(width_diff);
        Vec2 bottom_left = start_point.minus(width_diff);
        Vec2 bottom_right = end_point.minus(width_diff);

        Line top = new Line(top_left, top_right);
        Line bottom = new Line(bottom_left, bottom_right);
        Line left = new Line(bottom_left, top_left);
        Line right = new Line(bottom_right, top_right);

        for (Circle obstacle: obstacles){
          if (colliding(top, obstacle)){
            return true;
          }else if (colliding(bottom, obstacle)){
            return true;
          }else if(colliding(left, obstacle)){
            return true;
          }else if (colliding(right, obstacle)) {
            return true;
          }
        }
      }
      return false;
    }

  void draw(){
    for(int i = 0; i < num_of_joints; i++){
      // fill(random(255), random(255), random(255));
      pushMatrix();
      translate(joints[i].start_point.x,joints[i].start_point.y);
      rotate(angles[i]);
      rect(0, -armW/2, joints[i].length, armW);
      popMatrix();
    }
  }

  void attach(JointSystem js, int joint_index, boolean start_point, boolean isLeft){
    if (start_point)
      root = js.joints[0].start_point;
    else
      root = js.joints[joint_index].end_point;
    
    if (!isLeft)
      root = root.plus(new Vec2(armW/2, 0));
    else
      root = root.minus(new Vec2(armW/2, 0));
  }


  Vec2 closest_ground(){
    return new Vec2(endPoint.x, 960);
  }
  
  Vec2 to_the_right(){
    return new Vec2(endPoint.x+50, 960);
  }
}


// public boolean colliding_detection(){
//   for (JointSystem js: systems){
//     for (Joint j:js.joints){
//       float angle = j.angle;
//       float length = j.length;
//       Vec2 start_point = j.start_point;
//       Vec2 end_point = j.end_point;

//       float new_angle = -(PI/2 - angle);
//       float x1 = cos(new_angle) * (armW /2);
//       float y1 = sin(new_angle) * (armW /2);
//       Vec2 width_diff = new Vec2(x1, y1);

//       Vec2 top_left = start_point.plus(width_diff);
//       Vec2 top_right = end_point.plus(width_diff);
//       Vec2 bottom_left = start_point.minus(width_diff);
//       Vec2 bottom_right = end_point.minus(width_diff);

//       Line top = new Line(top_left, top_right);
//       Line bottom = new Line(bottom_left, bottom_right);
//       Line left = new Line(bottom_left, top_left);
//       Line right = new Line(bottom_right, top_right);

//       for (Circle obstacle: obstacles){
//         if (colliding(top, obstacle)){
//           return true;
//         }else if (colliding(bottom, obstacle)){
//           return true;
//         }else if(colliding(left, obstacle)){
//           return true;
//         }else if (colliding(right, obstacle)) {
//           return true;
//         }
//       }
//     }
//   }
//   return false;
// }



Joint[] rightjoints = new Joint[4];
Joint[] leftjoints = new Joint[4];
Joint[] bodys = new Joint[4];
Joint[] rightLegJoints = new Joint[4];
Joint[] leftLegJoints = new Joint[4];
Circle[] obstacles = new Circle[1];
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
// Vec2 start_l1,start_l2, start_l3, endPoint;
// Vec2 startToGoal, startToEndEffector;
// float dotProd, angleDiff;
Vec2 leftArmGoal;
Vec2 rightArmGoal;
Vec2 tempLeftArmGoal = new Vec2(0, 960);
Vec2 tempRightArmGoal = new Vec2(1280, 960);




//Root
Vec2 root = new Vec2(1280/2,960/2+45+120+140+30-200);

void setupSystem(){
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


void setup(){
  size(1280,960);
  surface.setTitle("Inverse Kinematics");
  camera = new Camera();
  camera.position = new PVector(475.04254, 103.900024, 496.1439);
  camera.theta = 0.4186;
  camera.phi = -0.1435;

  obstacles[0] = new Circle(new Vec2(900, 400), 30);

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

  if (!walking){
    rightLeg.ik(rightLeg.closest_ground());
    rightLeg.attach(body, -1, true, false);
    leftLeg.ik(leftLeg.closest_ground());
    leftLeg.attach(body, -1, true, true);
  }else{
    walking();
  }

}

void walking(){
  // while(true){
    rightLeg.ik(rightLeg.to_the_right());
    body.attach(rightLeg, -1, true, true);
  // }



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
  // camera.Update(1.0 / frameRate);
  if(paused){
    fk();
    solve();
  }
  
  body.draw();
  rightArm.draw();
  leftArm.draw();
  rightLeg.draw();
  leftLeg.draw();
  obstacles[0].display();
//   ambient(250, 100, 100);
//  // specular(120, 120, 180);
//   ambientLight(40, 20,40);
//   lightSpecular(255, 215, 215);
//   directionalLight(185, 195, 255, -1, 1.25, -1);
//   shininess(255);
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
 }else if(key == 'w' || key == 'W'){
  walking = !walking;
   if (walking){
     println("try walking");
     tempRightArmGoal = rightArm.endPoint;
   }else{
     println("stop walking");
     tempLeftArmGoal = leftArm.endPoint;
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
