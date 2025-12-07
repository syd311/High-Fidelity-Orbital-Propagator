clear; clc; close all;

% NASA JPL
fname = 'horizons_results.txt';
txt = [ ...
'$$SOE' newline ...
'2459945.500000000 = A.D. 2023-Jan-01 00:00:00.0000 TDB ' newline ...
' X =-4.852064473427364E+03 Y = 7.414325022167356E+03 Z =-8.537199433743186E+03' newline ...
' VX= 1.002885224408954E+00 VY= 4.506732973103485E+00 VZ= 3.315992625619580E+00' newline ...
'2459946.500000000 = A.D. 2023-Jan-02 00:00:00.0000 TDB ' newline ...
' X = 5.082263909490564E+03 Y = 1.001257098596962E+03 Z = 1.112729071419971E+04' newline ...
' VX= 7.671930524646494E-01 VY=-5.643633291369320E+00 VZ= 1.314655305697208E-01' newline ...
'$$EOE' ];
fid = fopen(fname, 'w'); fwrite(fid, txt); fclose(fid);
global const
const.mu_earth = 398600.4418;  
const.R_earth  = 6378.137;     
const.J2       = 1.082626e-3;  
const.mu_sun   = 1.32712e11;   
const.obliquity = deg2rad(23.4392911); 

% Parsing Data
file_content = fileread(fname);
expr = '[-+]?\d*\.?\d+[eE][-+]?\d+';
matches = regexp(file_content, expr, 'match');
nums = str2double(matches);
r0_ecl = nums(1:3)'; v0_ecl = nums(4:6)'; r_target_ecl = nums(end-5:end-3)';

% Rotating to Equatorial
R_x = [1, 0, 0; 0, cos(const.obliquity), -sin(const.obliquity); 0, sin(const.obliquity),  cos(const.obliquity)];
Y0 = [R_x * r0_ecl; R_x * v0_ecl]; 

% Simulating
options = odeset('RelTol', 1e-12, 'AbsTol', 1e-12);
fprintf('Calculating Trajectory...');
[T, Y_eq] = ode45(@satellite_dynamics, [0, 24*3600], Y0, options);
fprintf(' Done.\n');

% Validating
r_final_sim_ecl = R_x' * Y_eq(end, 1:3)'; 
error_mag = norm(r_final_sim_ecl - r_target_ecl);
accuracy = (1 - (error_mag / norm(r_target_ecl))) * 100;

%Visualisation
R_plot = (R_x' * Y_eq(:,1:3)')'; 
f = figure('Name', 'Mission Simulation', 'Color', 'k', 'Position', [100 100 1000 700]);
ax = gca;
set(ax, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'ZColor', 'w', 'GridColor', 'w', 'GridAlpha', 0.15);
hold on; axis equal; grid on;

try
    load('topo.mat', 'topo'); 
    [x, y, z] = sphere(50);
    props.FaceColor= 'texture';
    props.EdgeColor = 'none';
    props.CData = topo; 
    props.FaceLighting = 'gouraud';
    props.SpecularStrength = 0.4;
    s = surface(x*const.R_earth, y*const.R_earth, z*const.R_earth, props);
    demcmap(topo); 
catch
    [x, y, z] = sphere(50);
    surf(x*const.R_earth, y*const.R_earth, z*const.R_earth, ...
        'FaceColor', [0.1 0.2 0.8], 'EdgeColor', 'none', 'FaceAlpha', 1.0);
end
light('Position', [1 1 0], 'Style', 'infinite');
material shiny; % Makes oceans reflect light

num_stars = 500;
star_dist = 60000;
theta = 2*pi*rand(num_stars,1);
phi = acos(2*rand(num_stars,1)-1);
sx = star_dist * sin(phi) .* cos(theta);
sy = star_dist * sin(phi) .* sin(theta);
sz = star_dist * cos(phi);
plot3(sx, sy, sz, 'w.', 'MarkerSize', 1); 


plot3(R_plot(:,1), R_plot(:,2), R_plot(:,3), 'Color', [0 1 1], 'LineWidth', 2);

plot3(r0_ecl(1), r0_ecl(2), r0_ecl(3), 'g.', 'MarkerSize', 25);
plot3(r0_ecl(1), r0_ecl(2), r0_ecl(3), 'wo', 'MarkerSize', 8, 'LineWidth', 1.5);

plot3(r_target_ecl(1), r_target_ecl(2), r_target_ecl(3), 'r.', 'MarkerSize', 25);
plot3(r_target_ecl(1), r_target_ecl(2), r_target_ecl(3), 'wo', 'MarkerSize', 8, 'LineWidth', 1.5);


view(135, 25);
xlabel('X (km)'); ylabel('Y (km)'); zlabel('Z (km)');
title(sprintf('LAGEOS-1 ORBIT | ACCURACY: %.4f%%', accuracy), 'Color', 'w', 'FontSize', 14, 'FontWeight', 'bold');
subtitle('Validated against NASA JPL Horizons Data', 'Color', [0.8 0.8 0.8]);


lgd = legend('Earth', 'Starfield', 'Trajectory', 'Start', 'Target');
set(lgd, 'TextColor', 'w', 'Color', 'none', 'EdgeColor', 'none');


function dY = satellite_dynamics(t, Y)
    global const
    r = Y(1:3); v = Y(4:6); r_norm = norm(r);
    
    a_grav = - (const.mu_earth / r_norm^3) * r;
    
    x=r(1); y=r(2); z=r(3);
    J2_fac = (1.5 * const.J2 * const.mu_earth * const.R_earth^2) / r_norm^5;
    z2 = (z/r_norm)^2;
    a_J2 = [ J2_fac * x * (5*z2 - 1); J2_fac * y * (5*z2 - 1); J2_fac * z * (5*z2 - 3) ];

    dist_sun = 149.6e6; n_sun = 1.99e-7;
    r_sun_ecl = [dist_sun*cos(n_sun*t); dist_sun*sin(n_sun*t); 0];
    R_rot = [1, 0, 0; 0, cos(const.obliquity), -sin(const.obliquity); 0, sin(const.obliquity), cos(const.obliquity)];
    r_sun = R_rot * r_sun_ecl;
    r_ss = r_sun - r;
    a_sun = const.mu_sun * ( (r_ss/norm(r_ss)^3) - (r_sun/norm(r_sun)^3) );

    dY = [v; a_grav + a_J2 + a_sun];
end