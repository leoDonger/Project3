Camera camera;
boolean paused = false;
boolean use_acc_cap = false;
float acc_cap = 1;
// Vec2 start_l1,start_l2, start_l3, endPoint;
// Vec2 startToGoal, startToEndEffector;
// float dotProd, angleDiff;
Vec2 goal;

class Link{
  float length;
  float angle;
  Vec2 start_point;
  Vec2 end_point;
  float positive_joint_limit;
  float negative_joint_limit;

  Link(float l, float a, float pjl, float njl){
    length = l;
    angle = a;
    positive_joint_limit = pjl;
    negative_joint_limit = njl;
  }

  void ik(Vec2 goal, Vec2 endPoint){
    Vec2 startToGoal = goal.minus(start_point);
    Vec2 startToEndEffector = endPoint.minus(start_point);
    float dotProd = dot(startToGoal.normalized(),startToEndEffector.normalized());
    dotProd = clamp(dotProd,-1,1);
    float angleDiff = acos(dotProd);
    if (cross(startToGoal,startToEndEffector) < 0)
      angle += angleDiff * acc_cap;
    else
      angle -= angleDiff * acc_cap;
    
    if (negative_joint_limit != -1 && positive_joint_limit != -1){
      if (angle > positive_joint_limit)
        angle = positive_joint_limit;
      else if (angle < negative_joint_limit)
        angle = negative_joint_limit;
    }
  }
}

class JointSystem{
  int num_of_joints;
  Link[] joints;
  float[] angles;
  Vec2 root;
  Vec2 endPoint;

  JointSystem(Link[] a, Vec2 r){
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
      joints[j].ik(goal, endPoint);
      fk();
    }
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
}

Link[] rightjoints = new Link[4];
Link[] leftjoints = new Link[4];
Link[] bodys = new Link[4];
JointSystem rightArm;
JointSystem leftArm;
JointSystem body;
//Root
Vec2 root = new Vec2(1280/2,960/2 -200);

void setup(){
  size(1280,960);
  surface.setTitle("Inverse Kinematics");
  camera = new Camera();
  camera.position = new PVector(475.04254, 103.900024, 496.1439);
  camera.theta = 0.4186;
  camera.phi = -0.1435;


  bodys[0] = new Link(30, 0, PI/2, PI/2);
  bodys[1] = new Link(140, 0, 0, 0);
  bodys[2] = new Link(120, 0, 0, 0);
  bodys[3] = new Link(45, 0, 0, 0);
  body = new JointSystem(bodys, root);
  
  rightjoints[0] = new Link(30, 0.3, PI/2, 0);
  rightjoints[1] = new Link(140, 0.3, -1, -1);
  rightjoints[2] = new Link(120, 0.3, -1, -1);
  rightjoints[3] = new Link(45, 0.3, PI/2, -PI/2);
  rightArm = new JointSystem(rightjoints, body.joints[0].start_point.plus(new Vec2(armW, 0)));

  leftjoints[0] = new Link(30, -0.3, PI, PI/2);
  leftjoints[1] = new Link(140, -0.3, -1, -1);
  leftjoints[2] = new Link(120, -0.3, -1, -1);
  leftjoints[3] = new Link(45, -0.3, PI/2, -PI/2);
  leftArm = new JointSystem(leftjoints,  body.joints[0].start_point.minus(new Vec2(armW, 0)));

}


void solve(){
  goal = new Vec2(mouseX, mouseY);
  body.ik(goal);
  rightArm.ik(goal);
  leftArm.ik(goal);
  //println("Angle 0:",a0,"Angle 1:",a1,"Angle 2:",a2,"Angle 3:",a3);
}

void fk(){
  body.fk();
  rightArm.fk();
  leftArm.fk();
}

float armW = 20;
void draw(){
  background(255, 255, 255);
  // camera.Update(1.0 / frameRate);
  fk();
  solve();
  
  body.draw();
  rightArm.draw();
  leftArm.draw();
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
     acc_cap = 0.5;
   }else{
     println("acc cap stopped");
     acc_cap = 1;
   }
 }
camera.HandleKeyPressed();
}

void keyReleased()
{
camera.HandleKeyReleased();
}
