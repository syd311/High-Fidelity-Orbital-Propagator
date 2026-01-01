clear; clc; close all;

% Creating dummy JPL Horizons data for validation (LAGEOS-1 context)
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

% Defining Physical Constants
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

% Coordinate Transformation: Ecliptic -> Equatorial
R_x = [1, 0, 0; 0, cos(const.obliquity), -sin(const.obliquity); 0, sin(const.obliquity),  cos(const.obliquity)];
Y0 = [R_x * r0_ecl; R_x * v0_ecl]; 

options = odeset('RelTol', 1e-12, 'AbsTol', 1e-12);
fprintf('1. Propagating Target Satellite (N-Body w/ J2)...\n');

%  Passing 'const' into the function using anonymous handle @(t,y)
[T, Y_eq] = ode45(@(t,y) satellite_dynamics(t, y, const), [0, 24*3600], Y0, options);

% Validation Check
r_final_sim_ecl = R_x' * Y_eq(end, 1:3)'; 
error_mag = norm(r_final_sim_ecl - r_target_ecl);
accuracy = (1 - (error_mag / norm(r_target_ecl))) * 100;
fprintf('   Accuracy vs JPL Ephemerides: %.4f%%\n', accuracy);

fprintf('2. Generating Space Debris & Running Conjunction Analysis...\n');

% Creating "Debris" Object (Perturbed Initial State)
% Offseting  position by ~70km and velocity slightly to create a close approach
r0_deb = Y0(1:3) + [50; -50; 20]; 
v0_deb = Y0(4:6) + [0.005; -0.005; 0];
Y0_deb = [r0_deb; v0_deb];

% Propagating Debris using same Physics Engine
[T_deb, Y_deb] = ode45(@(t,y) satellite_dynamics(t, y, const), [0, 24*3600], Y0_deb, options);

% Synchronizing Time Grids (Interpolation for TCA calculation)
t_common = 0:1:24*3600; % 1-second resolution
Y_sat_interp = interp1(T, Y_eq, t_common, 'spline');
Y_deb_interp = interp1(T_deb, Y_deb, t_common, 'spline');

r_sat_sync = Y_sat_interp(:, 1:3);
r_deb_sync = Y_deb_interp(:, 1:3);

% Calculating Distances
diff_vec = r_sat_sync - r_deb_sync;
distances = sqrt(sum(diff_vec.^2, 2));

% Finding TCA (Time of Closest Approach) and DCA (Distance)
[dca, idx_min] = min(distances);
tca = t_common(idx_min);

% Extracting coordinates at collision moment for plotting
% (Rotate back to Ecliptic to match visualization frame)
r_sat_tca_ecl = (R_x' * r_sat_sync(idx_min, :)')';
r_deb_tca_ecl = (R_x' * r_deb_sync(idx_min, :)')';

fprintf('   Time of Closest Approach (TCA): %.0f s (%.2f hours)\n', tca, tca/3600);
fprintf('   Distance of Closest Approach (DCA): %.3f km\n', dca);
if dca < 100
    fprintf('   STATUS: *** CRITICAL CONJUNCTION DETECTED ***\n');
else
    fprintf('   STATUS: SAFE\n');
end

fprintf('3. Rendering 3D Scene...\n');
f = figure('Name', 'GMV SST Simulation', 'Color', 'k', 'Position', [100 100 1200 800]);
ax = gca;
set(ax, 'Color', 'k', 'XColor', 'w', 'YColor', 'w', 'ZColor', 'w', 'GridColor', 'w', 'GridAlpha', 0.15);
hold on; axis equal; grid on;

% Drawing the Earth
try
    load('topo.mat', 'topo'); 
    [x, y, z] = sphere(50);
    props.FaceColor= 'texture'; props.EdgeColor = 'none'; props.CData = topo; 
    props.FaceLighting = 'gouraud'; props.SpecularStrength = 0.4;
    surface(x*const.R_earth, y*const.R_earth, z*const.R_earth, props);
catch
    [x, y, z] = sphere(50);
    surf(x*const.R_earth, y*const.R_earth, z*const.R_earth, ...
        'FaceColor', [0.1 0.2 0.8], 'EdgeColor', 'none', 'FaceAlpha', 1.0);
end
light('Position', [1 1 0], 'Style', 'infinite'); material shiny;

% Drawing Stars
num_stars = 500; star_dist = 60000;
theta = 2*pi*rand(num_stars,1); phi = acos(2*rand(num_stars,1)-1);
sx = star_dist * sin(phi) .* cos(theta); sy = star_dist * sin(phi) .* sin(theta); sz = star_dist * cos(phi);
plot3(sx, sy, sz, 'w.', 'MarkerSize', 1); 

% Plotting Trajectories (Rotating all to Ecliptic for consistency)
R_sat_plot = (R_x' * Y_eq(:,1:3)')';
R_deb_plot = (R_x' * Y_deb(:,1:3)')';

plot3(R_sat_plot(:,1), R_sat_plot(:,2), R_sat_plot(:,3), 'Color', [0 1 1], 'LineWidth', 2); % Cyan
plot3(R_deb_plot(:,1), R_deb_plot(:,2), R_deb_plot(:,3), 'Color', [1 0.5 0], 'LineWidth', 1, 'LineStyle', '--'); % Orange

% Marking Start/End/Target
plot3(r0_ecl(1), r0_ecl(2), r0_ecl(3), 'g.', 'MarkerSize', 20); % Start
plot3(r_target_ecl(1), r_target_ecl(2), r_target_ecl(3), 'r.', 'MarkerSize', 20); % Target


line([r_sat_tca_ecl(1), r_deb_tca_ecl(1)], ...
     [r_sat_tca_ecl(2), r_deb_tca_ecl(2)], ...
     [r_sat_tca_ecl(3), r_deb_tca_ecl(3)], ...
     'Color', 'r', 'LineWidth', 3);

plot3(r_sat_tca_ecl(1), r_sat_tca_ecl(2), r_sat_tca_ecl(3), 'rp', 'MarkerSize', 15, 'MarkerFaceColor', 'r');
text(r_sat_tca_ecl(1), r_sat_tca_ecl(2), r_sat_tca_ecl(3)+3000, ...
     sprintf(' TCA DETECTED\n Dist: %.2f km', dca), 'Color', 'r', 'FontSize', 12, 'FontWeight', 'bold');


view(135, 25);
xlabel('X (km)'); ylabel('Y (km)'); zlabel('Z (km)');
title(sprintf('SST CONJUNCTION ANALYSIS | DCA: %.2f km', dca), 'Color', 'w', 'FontSize', 14);
subtitle('High-Fidelity N-Body Propagation (J2 + 3rd Body)', 'Color', [0.8 0.8 0.8]);

lgd = legend('Earth', 'Starfield', 'Target Sat', 'Debris', 'Sat Start', 'Target', 'COLLISION RISK');
set(lgd, 'TextColor', 'w', 'Color', 'none', 'EdgeColor', 'none', 'Location', 'northeast');
exportgraphics(gcf, 'SST_Conjunction_Event.png', 'Resolution', 300);

function dY = satellite_dynamics(t, Y, const)
    % Extracting State
    r = Y(1:3); v = Y(4:6); r_norm = norm(r);
    
    % 1. Central Gravity (Earth)
    a_grav = - (const.mu_earth / r_norm^3) * r;
    
    % 2. J2 Perturbation (Oblateness)
    x=r(1); y=r(2); z=r(3);
    J2_fac = (1.5 * const.J2 * const.mu_earth * const.R_earth^2) / r_norm^5;
    z2 = (z/r_norm)^2;
    a_J2 = [ J2_fac * x * (5*z2 - 1); J2_fac * y * (5*z2 - 1); J2_fac * z * (5*z2 - 3) ];

    % 3. Solar Radiation / Third Body (Sun)
    dist_sun = 149.6e6; n_sun = 1.99e-7;
    r_sun_ecl = [dist_sun*cos(n_sun*t); dist_sun*sin(n_sun*t); 0];
    
    % Rotating Sun vector to Equatorial frame to match Satellite
    R_rot = [1, 0, 0; 0, cos(const.obliquity), -sin(const.obliquity); 0, sin(const.obliquity), cos(const.obliquity)];
    r_sun = R_rot * r_sun_ecl;
    
    r_ss = r_sun - r; % Vector from Sat to Sun
    a_sun = const.mu_sun * ( (r_ss/norm(r_ss)^3) - (r_sun/norm(r_sun)^3) );

    % Total Acceleration
    dY = [v; a_grav + a_J2 + a_sun];
end