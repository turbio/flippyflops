include <BOSL2/std.scad>
include <BOSL2/screws.scad>
include <BOSL2/threading.scad>
include <BOSL2/gears.scad>

$fn = 100;

clamp_height = 4;
clamp_top_thickness = 2;

// magnet_core_r = .95; // nail
// magnet_core_r = 1.02+.02; // ferrite core
magnet_core_r = 1.82/2 + 0.02; // ferrite core second order

shaft_y = 14-9/2-1.6;
shaft_len = 9.64;

spool_spindle_r = 6;

// reference magnet core
// translate([100, 0, 0]) translate([0, shaft_y-8.34, 0]) cylinder(14, r=magnet_core_r);

module core_stand() {
	union() {
		difference() {
			translate([0, 0, 0]) cylinder(10, r=5.1/2+1);

			translate([0, 0, 0]) {
				cylinder(20, r=magnet_core_r);
				translate([-1/2, 0, 0]) cube([1,5,100]);
			}
		}

		cube([20, 20, 2], center=true);
	}
}

module motor_cut(l=0) {
	// motor body
	hull() {
		translate([0, 0, -2]) cylinder(h=100, r=14);
		translate([0, l, -2]) cylinder(h=100, r=14);
	}

	// screw holes
	hull() {
		translate([42/2-2.75, 0, 0]) cylinder(h=100, r=2);
		translate([42/2-2.75, l, 0]) cylinder(h=100, r=2);
	}

	hull() {
		translate([-42/2+2.75, 0, 0]) cylinder(h=1020, r=2);
		translate([-42/2+2.75, l, 0]) cylinder(h=1020, r=2);
	}
}

module motor_clamp() {
	arm_size = 8.5;

	difference() {
		union() {
			cylinder(clamp_height, r=16);

			difference() {
				translate([-42/2, -arm_size/2, clamp_height-2]) cube([42, arm_size, 2]);
				translate([42/2-2.5, 0, 0]) cylinder(20, r=3/2);
				translate([-42/2+2.5, 0, 0]) cylinder(20, r=3/2);
			}
		}

		translate([0, 0, -2]) cylinder(clamp_height, r=14.5); // motor body
		translate([0, -2, -2]) rotate([0, 0, -90-45]) cube([100,100,clamp_height]); // whire hole

		// cut across
		translate([-42/2, -arm_size/2, -2]) cube([42, arm_size, clamp_height]); // side holes

		// shaft hole
		translate([0, shaft_y, 0]) cylinder(20, r=9.2/2); // shaft hole

		// inner ring
		difference() {
			translate([0, 0, -2+.5]) cylinder(clamp_height, r=14.5);
			translate([0, 0, -2]) cylinder(20, r=12);
		}
	}
}

module motor_gear(lip=1) {
	shaft_radius = 5.1/2;
	difference() {
		union() {
			translate([0, 0, 0]) cylinder(h=lip, r=shaft_radius+1);

			translate([0, 0, lip]) spur_gear(
				circ_pitch=5,
				teeth=15,
				thickness=5,
				shaft_diam=0,
				anchor=BOTTOM
			);
		}

		translate([0, 0, -1]) intersection() {
			translate([0, 0, 0]) cylinder(h=10, r=shaft_radius);
			translate([-shaft_radius, 0-2.94/2, 0]) cube([10, 2.94, 10]);
		}
	}
}

*translate([40, 0, 0]) core_stand();

winder_cyl_inner_space = magnet_core_r + 1.5;
winder_cyl_wall_thickness = 1;
lock_ring_thick = 2;

module ender3_mount_holes() {
	translate([-7, 0, -1]) cylinder(r=1.7,h=20);
	translate([7, 0, -1]) cylinder(r=1.7,h=20);


	translate([-18, -28, -1]) cylinder(r=6,h=20);
}

bearing_h = 7;
bearing_outer_r = 22/2;
bearing_inner_r = 8/2;
bearing_recess_r = 19.2/2;

module bearing_608z() {
	difference() {
		cylinder(r=bearing_outer_r, h=bearing_h);
		translate([0, 0, -1]) cylinder(r=bearing_inner_r, h=10);
	}
}

bearing_lip = 1;
bearing_lip_h = 1;
bearing_wall = 2;

shaft_center_x = -12;

platform_depth = 50;
platform_width = 100;

shaft_center_y = -platform_depth/2;

motor_center_to_shaft = shaft_y;

motor_start_x = 18;

// ender mounted piece
color("green") difference() {
	union() {
		cube([platform_width, 3, 30], anchor=BOTTOM+FRONT);
		cube([platform_width, platform_depth, 3], anchor=BACK+BOTTOM);
		translate([shaft_center_x, shaft_center_y, 0]) cylinder(r=bearing_outer_r+bearing_wall, h=bearing_h+bearing_lip_h);

		// support
		translate([-60/2, 0, 3]) prismoid(
			size1=[2, platform_depth],
			size2=[2, 0],
			h=30-3,
			shift=[0, platform_depth/2],
			anchor=BOTTOM+BACK+LEFT
		);
		translate([0, 0, 3]) prismoid(
			size1=[2, platform_depth/3],
			size2=[2, 0],
			h=30-3,
			shift=[0, platform_depth/3/2],
			anchor=BOTTOM+BACK
		);
	}

	translate([shaft_center_x, shaft_center_y, bearing_lip_h]) cylinder(r=bearing_outer_r, h=bearing_h+1);
	translate([shaft_center_x, shaft_center_y, -1]) cylinder(r=bearing_outer_r-bearing_lip, h=bearing_lip_h+2);

	translate([0, 10, 20]) rotate([90, 0, 0]) ender3_mount_holes();

	translate([motor_start_x, shaft_center_y, -1]) rotate([00, 0, -90]) motor_cut(l=6);
}

shaft_lip_h = 1;
shaft_lip = 1;

color("blue") translate([shaft_center_x, shaft_center_y, 0]) difference() {
	union() {
		cylinder(h=bearing_h+bearing_lip_h+shaft_lip_h, r=bearing_inner_r);
		translate([0, 0, bearing_h+bearing_lip_h]) cylinder(h=shaft_lip_h, r=bearing_inner_r+shaft_lip);

		translate([0, 0, bearing_h+bearing_lip_h+shaft_lip_h]) spur_gear(
			circ_pitch=5,
			teeth=15,
			thickness=5,
			shaft_diam=0,
			anchor=BOTTOM
		);
	}

	translate([0, 0, -1]) cylinder(40, r=winder_cyl_inner_space);

	// gear chamfer
	translate([0, 0, bearing_h+bearing_lip_h+shaft_lip_h]) cylinder(r1=0, r2=bearing_inner_r*2, h=8);
}

// color("orange") translate([motor_start_x-motor_center_to_shaft, shaft_center_y, 4]) motor_gear();
color("orange") translate([15, shaft_center_y, 7]) rotate([0, 0, 360/15/2]) motor_gear(lip=2);

*color("grey") translate([shaft_center_x, shaft_center_y, bearing_lip_h]) bearing_608z();

spool_height = 50;
spool_length = 90;

// wire spool spindle
translate([shaft_center_x, shaft_center_y, 0]) {
	//translate([0, 0, 35]) rotate([0, 90, 0]) cylinder(95, r=spool_spindle_r);
	translate([-spool_length/2, 0, 0]) difference() {
		translate([0, 0, 0]) cuboid(
				[bearing_h,bearing_outer_r*2+2,spool_height+1],
				anchor=BOTTOM,
				rounding=bearing_outer_r+1,
				edges=[TOP+FRONT, TOP+BACK]
			);

		translate([-1, 0, spool_height]) rotate([0, 90, 0]) cylinder(h=20, r=bearing_outer_r, anchor=LEFT);
	}

	translate([spool_length/2, 0, 0]) difference() {
		translate([0, 0, 0]) cuboid(
				[bearing_h,bearing_outer_r*2+2,spool_height+1],
				anchor=BOTTOM,
				rounding=bearing_outer_r+1,
				edges=[TOP+FRONT, TOP+BACK]
			);

		translate([-1, 0, spool_height]) rotate([0, 90, 0]) cylinder(h=20, r=bearing_outer_r, anchor=LEFT);
	}

	//translate([spool_spindle_r, -2, 35]) cube([3,2*2,9]);
}
