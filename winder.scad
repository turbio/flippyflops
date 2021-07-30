$fn = 100;

clamp_height = 4;
clamp_top_thickness = 2;

// magnet_core_r = .95; // nail
magnet_core_r = 1.02+.05; // ferrite core

shaft_y = 14-9/2-1.6;
shaft_len = 9.64;
shaft_radius = 5.1/2;
arm_size = 8.5;

module motor_clamp() {
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

motor_clamp();

translate([-40, 8, 30]) rotate([0, 90, -90]) {
	motor_clamp();
	translate([20, -arm_size/2, 2]) cube([5, arm_size, 2]);
}

// base
if (true) difference() {
	union() {
		translate([-100/2, -100/2, 2]) cube([90, 60, 2]);

		translate([-100/2, -100/2, -25+2]) cube([5,5,25]);
		translate([-100/2+90-5, -100/2, -25+2]) cube([5,5,25]);
		translate([-100/2+90-5, -100/2+60-5, -25+2]) cube([5,5,25]);
		translate([-100/2, -100/2+60-5, -25+2]) cube([5,5,25]);
	}

	translate([0, 0, -5]) cylinder(20, r=20);
}

spindle_r = 6;

// wire spool spindle
translate([-95/2, -43, 5]) {
	translate([0, 0, 35]) rotate([0, 90, 0]) cylinder(95, r=spindle_r);
	translate([0, -spindle_r, 0]) cube([10,spindle_r*2,35]);

	translate([spindle_r, -2, 35]) cube([3,2*2,9]);
	translate([95-3, -2, 35]) cube([3,2*2,9]);
}

// motor shaft
if (false) union() {
	translate([0, shaft_y, 0]) cylinder(clamp_height+shaft_len-6, r=shaft_radius);
	intersection() {
			translate([0, shaft_y, 0]) cylinder(clamp_height+shaft_len, r=shaft_radius);
			translate([-shaft_radius, shaft_y-2.94/2, clamp_height+shaft_len-6]) cube([10, 2.94, 6]);
	}
}


// reference magnet core
//translate([0, shaft_y-8.34, clamp_height+shaft_len+2]) cylinder(14, r=magnet_core_r);

// motor shaft caps
if (true) for (i = [-3: 2]) {
	translate([i * 10, 10, 0]) difference() {
		translate([0, shaft_y, clamp_height+shaft_len-5]) cylinder(14+(i*.5), r=shaft_radius+1);

		translate([0, shaft_y, clamp_height+shaft_len+1]) {
			cylinder(20, r=magnet_core_r);
			translate([-1/2, 0, 0]) cube([1,5,100]);
		}

		union() intersection() {
			translate([0, shaft_y, 0]) cylinder(clamp_height+shaft_len, r=shaft_radius);
			translate([-shaft_radius, shaft_y-2.94/2, clamp_height+shaft_len-6]) cube([10, 2.94, 6]);
		}
	}
}

// this one worked the best
difference() {
	translate([0, shaft_y, clamp_height+shaft_len-5]) cylinder(14+(-3*.5), r=shaft_radius+1);

	translate([0, shaft_y, clamp_height+shaft_len+1]) {
		cylinder(20, r=magnet_core_r);
		translate([-1/2, 0, 0]) cube([1,5,100]);
	}

	union() intersection() {
		translate([0, shaft_y, 0]) cylinder(clamp_height+shaft_len, r=shaft_radius);
		translate([-shaft_radius, shaft_y-2.94/2, clamp_height+shaft_len-6]) cube([10, 2.94, 6]);
	}
}

// side motor shaft cap
translate([-35, -10, 25]) rotate([-90, 0, 0]) difference() {
	union() {
		translate([0, 0, 0]) cylinder(8, r=9);

		translate([8, 0, 0]) rotate([90, 0, 90]) difference() {
			translate([-1.5, 0, 0]) cube([4, 3, 25]);
			translate([0, -1, 20]) cube([1, 5, 4]);
		}
	}


	translate([0, 0, -5]) intersection() {
		translate([0, 0, 0]) cylinder(clamp_height+shaft_len, r=shaft_radius);
		translate([-shaft_radius, 0-2.94/2, clamp_height+shaft_len-6]) cube([10, 2.94, 6]);
	}
}

winder_arm_height = 38;

// stationary vertical arm
translate([0, -4, 1])
union() {
	difference() {
		translate([-2, 2.5, clamp_height]) cube([4, 3, winder_arm_height]);
		translate([-.5, 2, clamp_height+shaft_y+3]) cube([1, 5, winder_arm_height-10]);
	}

	translate([-4, 3-2, clamp_height]) cube([8, 4.5, 1]);
}

translate([0, 0, 25]) difference() {
	translate([-7/2, -3, 20]) cube([7,11,2]);

	// arm holes
	translate([0, -4, 1]) difference() {
		translate([-4.2/2, 2.5, clamp_height]) cube([4.2, 3.5, winder_arm_height]);

		translate([-.8/2, 2, clamp_height+shaft_y+3]) cube([.8, 5, winder_arm_height-12]);
	}

	translate([0, shaft_y, clamp_height+shaft_len]) cylinder(14, r=magnet_core_r+.1);
}

translate([0, 0, 30]) difference() {
	translate([-7/2, -3, 20]) cube([7,11,2]);

	// arm holes
	translate([0, -4, 1]) difference() {
		translate([-4.5/2, 2.5, clamp_height]) cube([4.5, 3.8, winder_arm_height]);

		translate([-.8/2, 2, clamp_height+shaft_y+3]) cube([.8, 5, winder_arm_height-12]);
	}

	translate([0, shaft_y, clamp_height+shaft_len]) cylinder(14, r=magnet_core_r+.1);
}
