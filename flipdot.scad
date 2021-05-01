// all measurements are in mm


standoff_len = 9.525;

bezel = 10;
frame_depth = 50;
dot_radius = 5;

panel_height_pad = 2;

panel_depth = 28.575;
panel_width = dot_radius*2*28;
panel_height = dot_radius*2*7 + panel_height_pad;

echo("total panel height", panel_height*2);
echo("total panel width", panel_width*2);

pcb_depth = 19.05;
pcb_width = 139.7;
pcb_height = 63.5;

pcb_offx = 74;
pcb_offy = 4;

panel_offset = 0;

base_side_w = 30;
base_mid_w = 60;

show_components = 0;

standoff_y_dist = 10;
standoff_x_dist = 14.7;

standoffs = [
	[standoff_x_dist, standoff_y_dist],
	[panel_width - standoff_x_dist, standoff_y_dist],
	[standoff_x_dist, panel_height - standoff_y_dist],
	[panel_width - standoff_x_dist, panel_height - standoff_y_dist],
];

print_area = [(panel_width*2+bezel*2)/3, 225, 250];

base_gap = pcb_depth/2;

standoff_hole_margin_x = 4;

// components to make modeling a bit easier, these should be turned off when
// exporting
if (show_components) {
	// flip dot panels
	translate([bezel,bezel,pcb_depth+standoff_len+panel_offset])
	for (px = [0, panel_width + 0]) {
		for (py = [0, panel_height + 0]) {

			translate([px,py, 0]) {
				// standoffs
				translate([0,0, -standoff_len]) color([.8,.8,.8])
					for (st = standoffs) translate(st) cylinder(h=standoff_len, r=2);

				// controller pcb
				color([0,1,0]) {
					translate([pcb_offx, pcb_offy, -standoff_len-pcb_depth])
					cube([pcb_width,pcb_height,pcb_depth]);
				}

				// acutal panel
				color([0,0,0])
					cube([panel_width, panel_height, panel_depth]);

				// dots
				for (dx = [0 : 27])
					for (dy = [0 : 6])
						translate([dx*10 + 5,dy*10 + 5,panel_depth+1])
							rotate([0,25,-45])
							color([1,1,1]) 
							difference() {
								cylinder(h=1,r=dot_radius);
								// this makes openscad really slow u_u
								// translate([dot_radius, 0, -1]) cylinder(h=3,r=2);
							}
			}
		}
	}

	// esp
	color([0,1,0])
		translate([250, 20, pcb_depth])
		cube([54.4,27.9,5]);
}

module frame() translate([bezel, bezel, 0]) union() {
	// base left / mid / right
	difference() {
		translate([0, 0, base_gap]) union() {
			cube([base_side_w, panel_height*2, pcb_depth-base_gap]);

			translate([panel_width-base_mid_w/2,0,0])
				cube([base_mid_w, panel_height*2, pcb_depth-base_gap]);

			translate([panel_width*2-base_side_w,0,0])
				cube([base_side_w, panel_height*2, pcb_depth-base_gap]);
		};

		for (px = [0, panel_width + 0]) {
			for (py = [0, panel_height + 0]) {
				// standoffs
				for (st = standoffs) {
					hull() {
						translate([px-standoff_hole_margin_x, py, -1]) translate(st) cylinder(h=pcb_depth*3, r=2);
						translate([px+standoff_hole_margin_x, py, -1]) translate(st) cylinder(h=pcb_depth*3, r=2);
					}

					translate([px, py, -2]) translate(st) cylinder(h=pcb_depth, r=8);
				}
			}
		};
	};

	// top
	translate([0,panel_height*2, 0]) difference() {
		translate([-bezel,0,0])
			cube([panel_width*2 + bezel*2, bezel, frame_depth]);
		translate([0,0,-frame_depth/2])
			rotate([0,0,135])
			cube([bezel*2,bezel*2,frame_depth*2]);
		translate([panel_width*2,0,-frame_depth/2])
			rotate([0,0,-45])
			cube([bezel*2,bezel*2,frame_depth*2]);
	};

	// bottom
	translate([0,-bezel,0]) difference() {
		translate([-bezel,0,0])
			cube([panel_width*2 + bezel*2, bezel, frame_depth]);
		translate([0,bezel,-frame_depth/2])
			rotate([0,0,135])
			cube([bezel*2,bezel*2,frame_depth*2]);
		translate([panel_width*2,bezel,-frame_depth/2])
			rotate([0,0,-45])
			cube([bezel*2,bezel*2,frame_depth*2]);
	};

	// left
	translate([-bezel,0, 0]) difference() {
		translate([0,-bezel,0])
			cube([bezel, panel_height*2+bezel*2, frame_depth]);
		translate([bezel,0,-frame_depth/2])
			rotate([0,0,-135])
			cube([bezel*2,bezel*2,frame_depth*2]);
		translate([bezel,panel_height*2,-frame_depth/2])
			rotate([0,0,45])
			cube([bezel*2,bezel*2,frame_depth*2]);
	};

	// right
	translate([panel_width*2,0, 0]) difference() {
		translate([0,-bezel,0])
			cube([bezel, panel_height*2+bezel*2, frame_depth]);
		translate([0,0,-frame_depth/2])
			rotate([0,0,-135])
			cube([bezel*2,bezel*2,frame_depth*2]);
		translate([0,panel_height*2,-frame_depth/2])
			rotate([0,0,45])
			cube([bezel*2,bezel*2,frame_depth*2]);
	}
}

joint_depth = 10;
joint_width = bezel/2;
joint_height = 5;
joint_pad = 5;

gender_diff = .5;

module box_joint(ext_r, female) {

	if (female) {
		if (ext_r) {
			for (i = [0: 2])
				translate([-.1, -.1, i*(joint_height+joint_pad)-(gender_diff/2)])
					cube([joint_depth+.2, joint_width+.2, joint_height+gender_diff]);
		} else {
			for (i = [0: 2])
				translate([-joint_depth-.1, -.1, i*(joint_height+joint_pad)-(gender_diff/2)])
					cube([joint_depth+.2, joint_width+.2, joint_height+gender_diff]);
		}
	} else {
		if (ext_r) {
			for (i = [0: 2])
				translate([-.1, 0, i*(joint_height+joint_pad)+(gender_diff/2)])
					cube([joint_depth+.1, joint_width, joint_height-(gender_diff)]);
		} else {
			for (i = [0: 2])
				translate([-joint_depth, 0, i*(joint_height+joint_pad)+(gender_diff/2)])
					cube([joint_depth, joint_width, joint_height-gender_diff]);
		}
	}
}

union() {
	intersection() {
		difference() {
			frame();

			translate([print_area.x, joint_width, joint_pad]) box_joint(female=true);
			translate([print_area.x, bezel+panel_height*2, joint_pad*2]) box_joint(female=true);
		}
		cube(print_area);
	}

	translate([print_area.x, bezel/2, joint_height*2]) box_joint(ext_r=true);
	translate([print_area.x, bezel+panel_height*2, joint_height*1]) box_joint(ext_r=true);
}


translate([35,0,0])
union() {
	intersection() {
		difference() {
			frame();

			translate([print_area.x, bezel/2, joint_pad*2]) box_joint(ext_r=true, female=true);
			translate([print_area.x, bezel+panel_height*2, joint_pad*1]) box_joint(ext_r=true, female=true);

			translate([print_area.x*2, bezel+panel_height*2, joint_pad*2]) box_joint(female=true);
			translate([print_area.x*2, bezel/2, joint_pad*1]) box_joint(female=true);
		}

		translate([print_area.x, 0, 0]) cube(print_area);
	}

	translate([print_area.x, bezel/2, joint_pad*1]) box_joint();
	translate([print_area.x, bezel+panel_height*2, joint_pad*2]) box_joint();

	translate([print_area.x*2, bezel+panel_height*2, joint_pad*1]) box_joint(ext_r=true);
	translate([print_area.x*2, bezel/2, joint_pad*2]) box_joint(ext_r=true);
}

translate([70,0,0])
union() {
	intersection() {
		difference() {
			frame();

			translate([print_area.x*2, bezel/2, joint_pad*2]) box_joint(ext_r=true, female=true);
			translate([print_area.x*2, bezel+panel_height*2, joint_pad*1]) box_joint(ext_r=true, female=true);
		}

		translate([print_area.x*2, 0, 0]) cube(print_area);
	}

	translate([print_area.x*2, bezel/2, joint_pad*1]) box_joint();
	translate([print_area.x*2, bezel+panel_height*2, joint_pad*2]) box_joint();
}

// lil spacer cause tolerance
spacer_width = 4.3;
spacer_extra_depth = 0.4;
translate([print_area.x+15, 0, 0]) difference() {
	cube([spacer_width, bezel, frame_depth]);
	translate([-10, joint_width-spacer_extra_depth, 5]) cube([100, 100, (5*6)]);
}

//#cube(print_area);
//#translate([35+print_area.x, 0, 0]) cube(print_area);
//#translate([70+print_area.x*2, 0, 0]) cube(print_area);
