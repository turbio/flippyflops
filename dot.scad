draw_cores = false;
draw_dot = false;
draw_core_caps = false;

$fn = 200;

//dot_rot = .055*360;
// dot_rot = .44*360;

//dot_rot = .36*360;

// dot_rot = (($t *(.44-.055)) + .055) * 360;

dot_rot = 0;

inf = 100;

dot_radius = 5;
dot_thiccness = .7;

pin_width = .8;
pin_extrusion = 1.6;

base_height = 3;
base_pad = .5;
dot_to_arm_pad = .5;
hole_radius_pad = .3;
hole_depth_pad = .2;

arm_width = 2.6;
arm_side_pad = 1;
arm_top_pad = 1;
base_width = 12;

// magnet_core_r = .95; // nail
magnet_core_r = 1.02+.02; // ferrite core
magnet_core_h = 14.83;

wall_wid = 1;
wall_hid = 3;

module dot() {
	// disc
	if (draw_dot)
	color([.8,.4,.4])
	translate([0, 0, base_height+dot_radius+base_pad]) rotate([0, 0, 45]) rotate([dot_rot, 0, 0]) rotate([0, 0, -45])
	//translate([20, 0, .5/2])
	difference() {
		rotate([0, 0, 45])
		union() {
			translate([0, 0, -(dot_thiccness)/2]) cylinder(dot_thiccness, r=dot_radius);
			cube([(dot_radius*2)+(pin_extrusion*2), pin_width, dot_thiccness], true);
		}

		// core hole
		rotate([0, 0, -45]) translate([dot_radius, 0, -1]) cylinder(10, r=magnet_core_r+.25);

		// magnet hole
		rotate([0,0,45]) cube([3.01,1.01,2], center=true);
	}

	// base
	color([.8,.8,.8])
	difference() {
		translate([-base_width/2, -base_width/2, 0+2])
			cube([ base_width, base_width, base_height + wall_hid-2]);

		// base cutout
		difference() {
			// top
			translate([wall_wid - base_width/2, wall_wid - base_width/2, 3])
				cube([base_width-(wall_wid*2),base_width-(wall_wid*2),20]);

			// hole supports
			translate([-3-2 + 3/2, 2 + 3/2, 2.5]) hull() {
				cylinder(2, r=2);
				translate([-3, 0, 0]) cylinder(2, r=2);
				translate([0, 3, 0]) cylinder(2, r=2);
			}


			translate([2+3/2, -3-2 + 3/2, 2.5]) rotate([0,0, 180]) hull() {
				cylinder(2, r=2);
				translate([-3, 0, 0]) cylinder(2, r=2);
				translate([0, 3, 0]) cylinder(2, r=2);
			}
		}

		// magnet core holes
		rotate([0, 0, -45]) translate([dot_radius, 0, -1]) cylinder(10, r=magnet_core_r);
		rotate([0, 0, -45]) translate([-(dot_radius), 0, -1]) cylinder(10, r=magnet_core_r);

		// magnet core coil cutout
		translate([2+3/2, -3-2 + 3/2, -1]) cylinder(3, r=3/2);
		translate([-3-2 + 3/2, 2 + 3/2, -1]) cylinder(3, r=3/2);
	}

	// arms
	color([.8,.8,.8])
	for (i = [0, 180]) {
		intersection() {
			rotate([0, 0, 45-i]) union() {
				difference() {
					translate([dot_radius+dot_to_arm_pad, -arm_width/2 - dot_to_arm_pad/2, 2])
						cube([arm_width, arm_width+dot_to_arm_pad, dot_radius+base_pad+(pin_width/2)+arm_top_pad+base_height-2]);

					translate([dot_radius+pin_extrusion+hole_depth_pad, 0, base_height+dot_radius+base_pad])
						rotate([0, -90, 0])
						cylinder(inf, r=(pin_width/2)+hole_radius_pad);
				}
			}

			translate([-base_width/2, -base_width/2, 0]) cube([base_width, base_width, inf]);
		}
	}
}

// core caps
union() {
	rotate([0, 0, -45]) translate([dot_radius, 0, -5]) union() {
		if (draw_cores) color([.2,.2,.2]) cylinder(magnet_core_h, r=magnet_core_r);

		if (draw_core_caps) difference() {
			translate([0, 0, -.5]) cylinder(1, r=magnet_core_r+1);
			cylinder(1, r=magnet_core_r);
			translate([0, 0, -1]) cylinder(2, r=.5);
		}
	}

	rotate([0, 0, 180-45]) translate([dot_radius, 0, -5]) union() {
		if (draw_cores) color([.2,.2,.2]) cylinder(magnet_core_h, r=magnet_core_r);

		if (draw_core_caps) difference() {
			translate([0, 0, -.5]) cylinder(1, r=magnet_core_r+1);
			cylinder(1, r=magnet_core_r);
			translate([0, 0, -1]) cylinder(2, r=.5);
		}
	}
}

for (x = [0: 1-1]) {
	for (y = [0: 1-1]) {
		translate([x * (base_width-wall_wid), y * (base_width-wall_wid), 0]) dot();
	}
}
