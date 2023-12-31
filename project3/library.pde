float acc_cap = 0.05;
float armW = 20;
Joint[] rightjoints = new Joint[4];
Joint[] leftjoints = new Joint[4];
Joint[] bodys = new Joint[4];
Joint[] rightLegJoints = new Joint[4];
Joint[] leftLegJoints = new Joint[4];
Circle[] obstacles = new Circle[];
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
Vec2 leftArmGoal;
Vec2 rightArmGoal;
Vec2 tempLeftArmGoal = new Vec2(0, 960);
Vec2 tempRightArmGoal = new Vec2(1280, 960);

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
      if (i == 0){
        // fill(120, 120, 120);
        fill(255, 215, 0);
      }else{
        fill(128, 0, 0);
        // fill(0, 200, 223);
      }
      pushMatrix();
      translate(joints[i].start_point.x,joints[i].start_point.y, -5);
      rotate(angles[i]);
      rect(0, -armW/2, joints[i].length, armW, 28);
      popMatrix();

      pushMatrix();
      translate(joints[i].start_point.x,joints[i].start_point.y, 5);
      rotate(angles[i]);
      rect(0, -armW/2, joints[i].length, armW, 28);
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


boolean fake_all_collision(){
  if(leftArm.colliding_detection() || rightArm.colliding_detection()){
    return true;
  }
  return false;
}



// physics and shape
public class Line{
  public Vec2 pt1, pt2;
  
  public Line(Vec2 pt1, Vec2 pt2){
    this.pt1 = pt1;
    this.pt2 = pt2;
  }

  public Vec2 vec(){
    return pt2.minus(pt1);
  }

  public float length(){
    return pt1.minus(pt2).length();
  }

  public void display(){
    line(pt1.x, pt1.y, pt2.x, pt2.y);
  }

  public String toString(){
    return pt1.toString();
  }
}


public class Circle{
  public Vec2 center;
  public float radius;
  
  public Circle(Vec2 center, float radius){
    this.center = center;
    this.radius = radius;
  }

  public void display(){
    circle(center.x, center.y, radius*2);
  }

  public String toString(){
    return center.toString();
  }
}


public boolean colliding(Line l, Circle c){ // check
  Vec2 toCircle1 = c.center.minus(l.pt1);
  Vec2 toCircle2 = c.center.minus(l.pt2);
  if (toCircle1.length() <= c.radius || toCircle2.length() <= c.radius) return true;

  float a = 1;  //Lenght of l_dir (we noramlized it)
  float b = -2*dot((l.vec()).normalized(),toCircle1); //-2*dot(l_dir,toCircle)
  float c_val = toCircle1.lengthSqr() - (c.radius)*(c.radius); //different of squared distances
  
  float d = b*b - 4*a*c_val; //discriminant 
  
  if (d >=0){ 
    //If d is positive we know the line is colliding, but we need to check if the collision line within the line segment
    //  ... this means t will be between 0 and the lenth of the line segment
    float t1 = (-b - sqrt(d))/(2*a); //Optimization: we only take the first collision [is this safe?]
    if (t1 > 0 && t1 < l.length()){
      return true;
    } 
  }
  return false;
}

Line collisionResponseStatic(Circle ball, Line line){
  Vec2 v1 = ball.center.minus(line.pt1);
  Vec2 v2 = line.pt2.minus(line.pt1);
  float proj = dot(v2, v1) / v2.length();
  Vec2 closest = line.pt1.plus(v2.normalized().times(proj));
  Vec2 dist = ball.center.minus(closest);

  Vec2 normal = new Vec2(-v2.y, v2.x).normalized();

  float d = dot(normal, dist);
  if (d < 0){
    normal.mul(-1);
  }
  normal.mul(-1);

  Vec2 outside_point = ball.center.plus(normal.times(ball.radius));

  Vec2 new_pt2 = outside_point.minus(line.pt1).normalized().times(v2.length());
  return new Line(new_pt2, line.pt1);
  //float angle = atan2(new_pt2.y - line.pt1.y, new_pt2.x - line.pt1.x);
  // ball.center = closest.plus(normal.times(ball.radius));
  // Vec2 velNormal = normal.times(dot(ball.vel,normal));
  // ball.vel.subtract(velNormal.times(1 + cor));
  //return angle;
}




// Camera

class Camera
{
 Camera()
 {
   position      = new PVector( 0, 0, 0 ); // initial position
   theta         = 0; // rotation around Y axis. Starts with forward direction as ( 0, 0, -1 )
   phi           = 0; // rotation around X axis. Starts with up direction as ( 0, 1, 0 )
   moveSpeed     = 50;
   turnSpeed     = 1.57; // radians/sec
   boostSpeed    = 10;  // extra speed boost for when you press shift
    
   // dont need to change these
   shiftPressed = false;
   negativeMovement = new PVector( 0, 0, 0 );
   positiveMovement = new PVector( 0, 0, 0 );
   negativeTurn     = new PVector( 0, 0 ); // .x for theta, .y for phi
   positiveTurn     = new PVector( 0, 0 );
   fovy             = PI / 4;
   aspectRatio      = width / (float) height;
   nearPlane        = 0.1;
   farPlane         = 10000;
 }
void Update(float dt)
 {
   theta += turnSpeed * ( negativeTurn.x + positiveTurn.x)*dt;
    
   // cap the rotation about the X axis to be less than 90 degrees to avoid gimble lock
   float maxAngleInRadians = 85 * PI / 180;
   phi = min( maxAngleInRadians, max( -maxAngleInRadians, phi + turnSpeed * ( negativeTurn.y + positiveTurn.y ) * dt ) );
    
   // re-orienting the angles to match the wikipedia formulas: https://en.wikipedia.org/wiki/Spherical_coordinate_system
   // except that their theta and phi are named opposite
   float t = theta + PI / 2;
   float p = phi + PI / 2;
   PVector forwardDir = new PVector( sin( p ) * cos( t ),   cos( p ),   -sin( p ) * sin ( t ) );
   PVector upDir      = new PVector( sin( phi ) * cos( t ), cos( phi ), -sin( t ) * sin( phi ) );
   PVector rightDir   = new PVector( cos( theta ), 0, -sin( theta ) );
   PVector velocity   = new PVector( negativeMovement.x + positiveMovement.x, negativeMovement.y + positiveMovement.y, negativeMovement.z + positiveMovement.z );
   position.add( PVector.mult( forwardDir, moveSpeed * velocity.z * dt ) );
   position.add( PVector.mult( upDir,      moveSpeed * velocity.y * dt ) );
   position.add( PVector.mult( rightDir,   moveSpeed * velocity.x * dt ) );
    
   aspectRatio = width / (float) height;
   perspective( fovy, aspectRatio, nearPlane, farPlane );
   camera( position.x, position.y, position.z,
           position.x + forwardDir.x, position.y + forwardDir.y, position.z + forwardDir.z,
           upDir.x, upDir.y, upDir.z );
 }
  
 // only need to change if you want difrent keys for the controls
 void HandleKeyPressed()
 {
   if ( key == 'w' || key == 'W' ) positiveMovement.z = 1;
   if ( key == 's' || key == 'S' ) negativeMovement.z = -1;
   if ( key == 'a' || key == 'A' ) negativeMovement.x = -1;
   if ( key == 'd' || key == 'D' ) positiveMovement.x = 1;
   if ( key == 'q' || key == 'Q' ) positiveMovement.y = 1;
   if ( key == 'e' || key == 'E' ) negativeMovement.y = -1;
    
   if ( key == 'r' || key == 'R' ){
    //  Camera defaults = new Camera();
    //  position = defaults.position;
    //  theta = defaults.theta;
    //  phi = defaults.phi;
    camera.position = new PVector(719.04254, 117.900024, 545.1439);
    camera.theta = 0.131;
    camera.phi = -0.6536;
   }
    
   if ( keyCode == LEFT )  negativeTurn.x = 1;
   if ( keyCode == RIGHT ) positiveTurn.x = -0.5;
   if ( keyCode == UP )    positiveTurn.y = 0.5;
   if ( keyCode == DOWN )  negativeTurn.y = -1;
    
   if ( keyCode == SHIFT ) shiftPressed = true; 
   if (shiftPressed){
     positiveMovement.mult(boostSpeed);
     negativeMovement.mult(boostSpeed);
   }

   if ( key == 'p' || key == 'P'){
     println("position:", position.x, position.y, position.z);
     println("theta:", theta);
     println("phi:", phi);

   }
 }

   void HandleKeyReleased()
 {
   if ( key == 'w' || key == 'W' ) positiveMovement.z = 0;
   if ( key == 'q' || key == 'Q' ) positiveMovement.y = 0;
   if ( key == 'd' || key == 'D' ) positiveMovement.x = 0;
   if ( key == 'a' || key == 'A' ) negativeMovement.x = 0;
   if ( key == 's' || key == 'S' ) negativeMovement.z = 0;
   if ( key == 'e' || key == 'E' ) negativeMovement.y = 0;
    
   if ( keyCode == LEFT  ) negativeTurn.x = 0;
   if ( keyCode == RIGHT ) positiveTurn.x = 0;
   if ( keyCode == UP    ) positiveTurn.y = 0;
   if ( keyCode == DOWN  ) negativeTurn.y = 0;
    
   if ( keyCode == SHIFT ){
     shiftPressed = false;
     positiveMovement.mult(1.0/boostSpeed);
     negativeMovement.mult(1.0/boostSpeed);
   }
 }
  
 // only necessary to change if you want different start position, orientation, or speeds
 PVector position;
 float theta;
 float phi;
 float moveSpeed;
 float turnSpeed;
 float boostSpeed;
  
 // probably don't need / want to change any of the below variables
 float fovy;
 float aspectRatio;
 float nearPlane;
 float farPlane;  
 PVector negativeMovement;
 PVector positiveMovement;
 PVector negativeTurn;
 PVector positiveTurn;
 boolean shiftPressed;
};




public class Vec2 {
  public float x, y;
  
  public Vec2(float x, float y){
    this.x = x;
    this.y = y;
  }
  
  public String toString(){
    return "(" + x+ "," + y +")";
  }
  
  public float length(){
    return sqrt(x*x+y*y);
  }
  
  public float lengthSqr(){
    return x*x+y*y;
  }

  public Vec2 plus(Vec2 rhs){
    return new Vec2(x+rhs.x, y+rhs.y);
  }
  
  public void add(Vec2 rhs){
    x += rhs.x;
    y += rhs.y;
  }
  
  public Vec2 minus(Vec2 rhs){
    return new Vec2(x-rhs.x, y-rhs.y);
  }
  
  public void subtract(Vec2 rhs){
    x -= rhs.x;
    y -= rhs.y;
  }
  
  public Vec2 times(float rhs){
    return new Vec2(x*rhs, y*rhs);
  }
  
  public void mul(float rhs){
    x *= rhs;
    y *= rhs;
  }
  
  public void clampToLength(float maxL){
    float magnitude = sqrt(x*x + y*y);
    if (magnitude > maxL){
      x *= maxL/magnitude;
      y *= maxL/magnitude;
    }
  }
  
  public void setToLength(float newL){
    float magnitude = sqrt(x*x + y*y);
    x *= newL/magnitude;
    y *= newL/magnitude;
  }
  
  public void normalize(){
    float magnitude = sqrt(x*x + y*y);
    x /= magnitude;
    y /= magnitude;
  }
  
  public Vec2 normalized(){
    float magnitude = sqrt(x*x + y*y);
    return new Vec2(x/magnitude, y/magnitude);
  }
  
  public float distanceTo(Vec2 rhs){
    float dx = rhs.x - x;
    float dy = rhs.y - y;
    return sqrt(dx*dx + dy*dy);
  }
}

Vec2 interpolate(Vec2 a, Vec2 b, float t){
  return a.plus((b.minus(a)).times(t));
}

float interpolate(float a, float b, float t){
  return a + ((b-a)*t);
}

float dot(Vec2 a, Vec2 b){
  return a.x*b.x + a.y*b.y;
}

float cross(Vec2 a, Vec2 b){
  return a.x*b.y - a.y*b.x;
}

Vec2 mid_point(Vec2 a, Vec2 b){
  return new Vec2((a.x + b.x) / 2, (a.y + b.y) / 2);
}

Vec2 projAB(Vec2 a, Vec2 b){
  return b.times(a.x*b.x + a.y*b.y);
}

float clamp(float f, float min, float max){
  if (f < min) return min;
  if (f > max) return max;
  return f;
}
