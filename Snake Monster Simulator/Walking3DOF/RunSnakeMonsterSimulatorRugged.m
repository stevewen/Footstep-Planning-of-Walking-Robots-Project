% Run this script to load all the simulation parameters into the workspace
%
% Author: Simon Kalouche
% BioRobotics Lab

clc
close all
% clear all

%% 1) Hexapod Parameters
% input SM params
SMparams = SM_Params();
l = SMparams.leg.lengths;
m = SMparams.leg.mass;   
m_body = SMparams.body.mass;        %[kg] body mass
i_body = SMparams.body.inertia;     %[kg-m^2] body inertia

%link lengths [m] 
l0=l(1); l1=l(2); l2=l(3); l3a=l(4);l3b=l(5);

%link masses [kg]
m1=m(1); m2=m(2); m3=m(3);

%link inertias [kg-m^2]
il1 = SMparams.leg.inertia(:,:,1);
il2 = SMparams.leg.inertia(:,:,2);
il3 = SMparams.leg.inertia(:,:,3);

%leg locations on torso relative to COM
xc = SMparams.body.leg(1,2);            %[m]
yc = SMparams.body.leg(1,3);            %[m]
zc = SMparams.body.leg(1,4);            %[m]

% Right leg link lengths
RL0 = [l0 0 0];
RL1 = [l1 0 0];
RL2 = [l2 0 0];
RL3 = [l3a 0 -l3b];

% Left leg link lengths
LL0 = [-l0 0 0];
LL1 = [-l1 0 0];
LL2 = [-l2 0 0];
LL3 = [-l3a 0 -l3b];

% actuator parameters
Tmax = 70;      %[N/m] 12

%PD control gains for joints 1,2,3
%P kains
kp1 = 150;  kp2 = 150; kp3 = 150;
%D gains
kd1 = 150; kd2 = 150; kd3 = 150;        

%% 2) World Parameters

% Ground Surface World Size
Worldx = 10;        %[m]
Worldy = 10;        %[m]

% terrain
% EasyTest.png terrain height map
load('terrain');  % a random terrain
dist2 = terrain;
terrain = ReadTerrain('EasyTest.png', 0);
terrain = 5.*terrain;
make_terrain(terrain, 'EasyTest.xyz');

% Desk figure from Angel
load('desk.mat');
terrain = tmp - 0.11;
desk = terrain;
dist2  = terrain;
make_terrain(desk, 'Desk.xyz');
terrain = 10*terrain;  % scale

[terrainX, terrainY] = size(terrain);

% % Ground slope 
% zGround = .4;   %0.4
% GroundIncline = rad2deg(atan(zGround/1));

% Rugged Terrain:  zGround(1000*round(u(1)), 1000*round(u(2)))
amp = .02;       % [m] max amplitude or height of terrain
freqT = 6;       % frequency of oscillations in ground terrain
res = 10;
load WorldData4SM.mat
% for x = 10:res:Worldx*1000
%     for y = 10:res:Worldy*1000
%         
%         % calculate ground height
%         zGround(x,y) = amp*sin(freqT*x)+amp*cos(freqT*y);
%         
%         % set color for plotting
%         if (zGround(x,y) > 0)
%             color = (zGround(x,y)/max(zGround(:)))*[1 1 1];
%         else
%             color = (abs(zGround(x,y))/max(zGround(:)))*[0 1 1];
%         end
%         
%         figure(1);
%         plot3(x/1000,y/1000,zGround(x,y),'.','Color',color,'MarkerSize',10);
%         hold on
%         grid on
%         axis equal
%         %drawnow     
%     end  
% end


%% 3) Ground Interaction Model 

%--------------------------------------------------------
% Vertical component
m = 2; %[kg]
g = 9.81; %[kg]

% stiffness of vertical ground interaction
k_gn = m*g/0.001; %[N/m]

% max relaxation speed of vertical ground interaction
v_gn_max = 0.03; %[m/s]

%--------------------------------------------------------

%--------------------------------------------------------
% Horizontal component
% sliding friction coefficient
mu_slide = 0.85; %original: .8

% sliding to stiction transition velocity limit
vLimit = 0.01; %[m/s] original: .01

% stiffness of horizontal ground stiction
k_gt = m*g/0.001; %[N/m] original: m*g/0.1

% max relaxation speed of horizontal ground stiction
v_gt_max = 0.03; %[m/s] original: 0.03

% stiction to sliding transition coefficient
mu_stick = 0.9; %original: .9
%--------------------------------------------------------


%% 4) Generate Foot Trajectory
TerrainFile = 'EasyTest.png';
ShowTerrain = 0;

% CostMapHigh: 10 by 10
% CostMap: 100 by 100
%[CostMapHigh, CostMap] = Train_cost_func(TerrainFile, ShowTerrain); % 100 by 100 matrix
[CostMapHigh, CostMap] = Train_cost_func_RF(TerrainFile, ShowTerrain);
Load


% High level planning
rob_path = HighLevelPlan(CostMapHigh);
[c1, c2] = size(rob_path);

% generate high level path
numStep = 5; %number of steps to take
step_freq = 20;  %[s] time for leg to move thru trajectory for 1 step
num = 100; % number of increments per step; must be a number divisible by 4
joint_angles = zeros(3, 6, num*numStep*c1);
% joint_angles = zeros(3, 6, num);

for i = 1:c1  % c1 path transitions
     joint_angle = GenerateFootTraj(rob_path(i,1), rob_path(i,2), numStep, step_freq, num);
% for i = 1:1
%     joint_angle = GenerateFootTraj(-0.2, 0, numStep, step_freq, num);
    for j = 1:numStep  % repeat footstep
        joint_angles(:, :, (((i-1)*numStep+(j-1))*num+1):((i-1)*numStep+(j))*num) = joint_angle;
    end
end

% for j = 1:num
%     % for limb(s) that are manipulating things
%     joint_angles(:,7,j) = IK([x3(j), y3(j), z3(j)]); 
% end

% ------------------- publish msg to the robot ------------------------ %
for k = 1:6
    % Repeat angles for however many number of steps the simulation is
    % specified for            
%     for i = 1:(numStep)
%         hipM(:,i) = joint_angles(1,k,:);
%         kneeM(:,i) = joint_angles(2,k,:);
%         ankleM(:,i) = joint_angles(3,k,:);
%     end
%     hipM(:,1) = joint_angles(1,k,:);
%     kneeM(:,1) = joint_angles(2,k,:);
%     ankleM(:,1) = joint_angles(3,k,:);
    hipV = joint_angles(1,k,:);
    kneeV = joint_angles(2,k,:);
    ankleV = joint_angles(3,k,:);

    % merge all columns into 1 column
%     hipV = hipM(:);
%     kneeV = kneeM(:);
%     ankleV = ankleM(:);
    
    % Leg joint position control trajectory timeseries
    leg(k).hip.angles = timeseries(hipV);
    leg(k).knee.angles = timeseries(kneeV);
    leg(k).ankle.angles = timeseries(ankleV);
    leg(k).hip.angles.time = leg(k).hip.angles.time*(step_freq/num);
    leg(k).knee.angles.time = leg(k).knee.angles.time*(step_freq/num);
    leg(k).ankle.angles.time = leg(k).ankle.angles.time*(step_freq/num);

    % initial conditions
    leg(k).hip.IC = joint_angles(1,k,1);
    leg(k).knee.IC = joint_angles(2,k,1);
    leg(k).ankle.IC = joint_angles(3,k,1);
end

%% Change Gait Type

% %turn left
% leg(2).hip.angles.Data = -leg(1).hip.angles.Data;
% leg(4).hip.angles.Data = -leg(3).hip.angles.Data;
% leg(6).hip.angles.Data = -leg(5).hip.angles.Data;

% %turn right
% leg(1).hip.angles.Data = -leg(2).hip.angles.Data;
% leg(3).hip.angles.Data = -leg(4).hip.angles.Data;
% leg(5).hip.angles.Data = -leg(6).hip.angles.Data;

% % skating??
% leg(2) = leg(1);
% leg(3) = leg(1);
% leg(4) = leg(1);
% leg(5) = leg(1);
% leg(6) = leg(1);

%  Manipulating legs Gaits
% leg(6) = leg(7);   %lift up one leg

% % quadruped walking
% leg(6) = leg(4);
% leg(5) = leg(3);
% leg(4) = leg(7);
% leg(3) = leg(7);

% % hind legs lifted up
% leg(1) = leg(7);
% leg(2) = leg(7);

%% RUN SIMULATOR
% figure(3)
% mesh(terrain);
% axis([0 10 0 10 0 1]);
sim('hexapod_bodyrugged.slx')







