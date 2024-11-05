standoff_len = 9.525;

bezel = 10;
frame_depth = 55;
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

render_panel = false;

render_split = true;

standoff_y_dist = 10;
standoff_x_dist = 14.7;

standoffs = [
	[standoff_x_dist, standoff_y_dist],
	[panel_width - standoff_x_dist, standoff_y_dist],
	[standoff_x_dist, panel_height - standoff_y_dist],
	[panel_width - standoff_x_dist, panel_height - standoff_y_dist],
];

print_area = [(panel_width*2+bezel*2)/3, 225, 250];

base_gap = 0;

standoff_hole_margin_x = 4;

module m4_screw_head_hole() {
	rotate([0, 90, 0]) cylinder(20, r=4.1, $fs=.1);
}

module m4_nut_hole() {
	rotate([0, 90, 0]) cylinder(3, r=4.1, $fn=6);
}

module m4_thread_hole(shaft_l) {
	rotate([0, 90, 0]) cylinder(shaft_l, r=.75*3, $fs=.1);
}

// components to make modeling a bit easier, these should be turned off when
// exporting
if (render_panel) {
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

mount_bracket_w = 15;
mount_bracket_h = 30;
bracket_support_ext = 30;
mount_bracket_thickness = 5;
mount_bracket_gap_to_wall = 5;
mount_hole_r = 4;

module mount_post(r_bump=0,h=20) {
	hull() {
		translate([0, 2, 0]) cylinder(h, r=mount_hole_r+r_bump, $fs=.1);
		translate([0, -2, 0]) cylinder(h, r=mount_hole_r+r_bump, $fs=.1);
	}
}

module mount_holes() {
	difference() {
		union() {
			linear_extrude(mount_bracket_thickness) polygon([
					[0, -bracket_support_ext],
					[mount_bracket_w, 0],
					[mount_bracket_w, mount_bracket_h],
					[0, mount_bracket_h+bracket_support_ext],
				]);
		}

		translate([mount_bracket_w/2, mount_bracket_h/2, -5]) mount_post();
	}
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

	translate([base_side_w, panel_height-mount_bracket_h/2, mount_bracket_gap_to_wall]) mount_holes();
	translate([panel_width-base_mid_w/2, panel_height-mount_bracket_h/2, mount_bracket_gap_to_wall]) mirror([1, 0, 0]) mount_holes();
	translate([panel_width+base_mid_w/2, panel_height-mount_bracket_h/2, mount_bracket_gap_to_wall]) mount_holes();
	translate([panel_width*2-base_side_w, panel_height-mount_bracket_h/2, mount_bracket_gap_to_wall]) mirror([1, 0, 0]) mount_holes();

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

gender_gap = .5;

module todo_snap_joint(ext_r, female) {
	if (female) {
		if (ext_r) {
			for (i = [0: 2])
				translate([-.1, -.1, i*(joint_height+joint_pad)-(gender_gap/2)])
					cube([joint_depth+.2, joint_width+.2, joint_height+gender_gap]);
		} else {
			for (i = [0: 2])
				translate([-joint_depth-.1, -.1, i*(joint_height+joint_pad)-(gender_gap/2)])
					cube([joint_depth+.2, joint_width+.2, joint_height+gender_gap]);
		}
	} else {
		if (ext_r) {
			for (i = [0: 2])
				translate([-.1, 0, i*(joint_height+joint_pad)+(gender_gap/2)])
					cube([joint_depth+.1, joint_width, joint_height-(gender_gap)]);
		} else {
			for (i = [0: 2])
				translate([-joint_depth, 0, i*(joint_height+joint_pad)+(gender_gap/2)])
					cube([joint_depth, joint_width, joint_height-gender_gap]);
		}
	}
}

snap_beam_depth = 10;
snap_deflection = 1;
snap_hole = 2;
snap_beam_base_height = 2;
snap_beam_tip_height = 1;

module snap_joint() {
	rotate([90, 0, 0]) linear_extrude(3) {
		polygon([
			[0, 0],
			[snap_beam_depth, snap_beam_base_height-snap_beam_tip_height],
			[snap_beam_depth, snap_beam_base_height],
			[snap_beam_depth-snap_hole, snap_beam_base_height+snap_deflection],
			[snap_beam_depth-snap_hole, snap_beam_base_height],
			[0, snap_beam_base_height],
		]);
	}
}

screw_support_w = 4;

module screw_join_nut_side() {
	translate([-2-screw_support_w, 0, 0]) for (d = [0 : 10]) {
		translate([0, d, 0]) m4_nut_hole();
	}
	translate([-2-screw_support_w-6, 0, 0]) m4_thread_hole(shaft_l=20);
}

module screw_join_head_side() {
	translate([screw_support_w, 0, 0]) for (d = [0 : 10]) {
		translate([0, d, 0]) m4_screw_head_hole();
	}
	translate([-3, 0, 0]) m4_thread_hole(shaft_l=screw_support_w+5);
}

if (render_split) {
	// left
	translate([0, 0, 0])
	union() {
		intersection() {
			difference() {
				frame();

				*translate([print_area.x, joint_width, joint_pad]) todo_snap_joint(female=true);
				*translate([print_area.x, joint_width, joint_pad]) snap_joint();

				*translate([print_area.x, bezel+panel_height*2, joint_pad*2]) todo_snap_joint(female=true);

				translate([print_area.x, joint_width, 10]) screw_join_nut_side();
				translate([print_area.x, joint_width, frame_depth-10]) screw_join_nut_side();

				translate([print_area.x, bezel+panel_height*2+joint_width, 10]) rotate([180, 0, 0]) screw_join_nut_side();
				translate([print_area.x, bezel+panel_height*2+joint_width, frame_depth-10]) rotate([180, 0, 0]) screw_join_nut_side();
			}

			cube(print_area);
		}

		*translate([print_area.x, bezel/2, joint_height*2]) todo_snap_joint(ext_r=true);
		*translate([print_area.x, bezel/2, joint_height*2]) snap_joint();

		*translate([print_area.x, bezel+panel_height*2, joint_height*1]) todo_snap_joint(ext_r=true);
	}

	translate([35,0,0])
	union() {
		intersection() {
			difference() {
				frame();

				*translate([print_area.x, bezel/2, joint_pad*2]) todo_snap_joint(ext_r=true, female=true);
				*translate([print_area.x, bezel+panel_height*2, joint_pad*1]) todo_snap_joint(ext_r=true, female=true);

				*translate([print_area.x*2, bezel+panel_height*2, joint_pad*2]) todo_snap_joint(female=true);
				*translate([print_area.x*2, bezel/2, joint_pad*1]) todo_snap_joint(female=true);

				translate([print_area.x, joint_width, 10]) screw_join_head_side();
				translate([print_area.x, joint_width, frame_depth-10]) screw_join_head_side();

				translate([print_area.x, bezel+panel_height*2+joint_width, 10]) rotate([180, 0, 0]) screw_join_head_side();
				translate([print_area.x, bezel+panel_height*2+joint_width, frame_depth-10]) rotate([180, 0, 0]) screw_join_head_side();

				translate([print_area.x*2, bezel+panel_height*2+joint_width, 10]) rotate([180, 180, 0]) screw_join_head_side();
				translate([print_area.x*2, bezel+panel_height*2+joint_width, frame_depth-10]) rotate([180, 180, 0]) screw_join_head_side();

				translate([print_area.x*2, joint_width, 10]) rotate([0, 180, 0]) screw_join_head_side();
				translate([print_area.x*2, joint_width, frame_depth-10]) rotate([0, 180, 0]) screw_join_head_side();
			}

			translate([print_area.x, 0, 0]) cube(print_area);
		}

		*translate([print_area.x, bezel/2, joint_pad*1]) todo_snap_joint();
		*translate([print_area.x, bezel+panel_height*2, joint_pad*2]) todo_snap_joint();

		*translate([print_area.x*2, bezel+panel_height*2, joint_pad*1]) todo_snap_joint(ext_r=true);
		*translate([print_area.x*2, bezel/2, joint_pad*2]) todo_snap_joint(ext_r=true);
	}

	translate([70,0,0])
	union() {
		intersection() {
			difference() {
				frame();

				*translate([print_area.x*2, bezel/2, joint_pad*2]) todo_snap_joint(ext_r=true, female=true);
				*translate([print_area.x*2, bezel+panel_height*2, joint_pad*1]) todo_snap_joint(ext_r=true, female=true);

				translate([print_area.x*2, joint_width, 10]) rotate([0, 180, 0]) screw_join_nut_side();
				translate([print_area.x*2, joint_width, frame_depth-10]) rotate([0, 180, 0]) screw_join_nut_side();

				translate([print_area.x*2, bezel+panel_height*2+joint_width, 10]) rotate([180, 180, 0]) screw_join_nut_side();
				translate([print_area.x*2, bezel+panel_height*2+joint_width, frame_depth-10]) rotate([180, 180, 0]) screw_join_nut_side();
			}

			translate([print_area.x*2, 0, 0]) cube(print_area);
		}

		*translate([print_area.x*2, bezel/2, joint_pad*1]) todo_snap_joint();
		*translate([print_area.x*2, bezel+panel_height*2, joint_pad*2]) todo_snap_joint();
	}
} else {
	frame();
}

// lil spacer cause tolerance
spacer_width = 4.4;
spacer_extra_depth = 0.4;
*translate([print_area.x+15, 0, 0]) difference() {
	cube([spacer_width, bezel, frame_depth]);
	translate([-10, joint_width-spacer_extra_depth, 5]) cube([100, 100, (5*6)]);
}

esp32_dims = [54.29, 28.08, 12.6];

// esp32 holster
translate([100, 20, 0]) {
	translate([0, -2, 0]) cube([esp32_dims.x/2, 2, esp32_dims.z]);
	translate([0, -2, esp32_dims.z]) cube([esp32_dims.x/2, 4, 2]);

	translate([0, esp32_dims.y, 0]) cube([esp32_dims.x/2, 2, esp32_dims.z]);
	translate([0, esp32_dims.y-2, esp32_dims.z]) cube([esp32_dims.x/2, 4, 2]);
	cube([esp32_dims.x/2, esp32_dims.y, 2]);
}

wall_hook_w = 14;
wall_hook_h = 20;
wall_nail_hole_r = 2;

// wall hook
translate([60, 80, 0]) union() {
	difference() {
		minkowski() {
			cube([wall_hook_w, wall_hook_h, 3]);
		}

		translate([wall_hook_w-wall_nail_hole_r-1.5, wall_hook_h-wall_nail_hole_r-2.5, -1]) rotate([-15, 0, 0]) cylinder(20, r=wall_nail_hole_r, $fs=.1);
		translate([0+wall_nail_hole_r+1.5, wall_hook_h-wall_nail_hole_r-2.5, -1]) rotate([-15, 0, 0]) cylinder(20, r=wall_nail_hole_r, $fs=.1);
	}

	translate([wall_hook_w/2, wall_hook_h/3, 0]) difference() {
		mount_post(
			r_bump=-.5,
			h=mount_bracket_gap_to_wall+mount_bracket_thickness+10
		);

		translate([-50, 2, mount_bracket_gap_to_wall]) minkowski() {
			union() {
				cube([100, 100, mount_bracket_thickness+2]);
				translate([0, 0, mount_bracket_thickness+2]) rotate([-45, 0, 0]) cube([100, 100, mount_bracket_thickness+2]);
			}
			sphere(0.5, $fs=.1);
		}
	}
}

//#cube(print_area);
//#translate([35+print_area.x, 0, 0]) cube(print_area);
//#translate([70+print_area.x*2, 0, 0]) cube(print_area);
