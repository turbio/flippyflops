inf = 100;

dot_radius = 5;
dot_thiccness = .6;

pin_width = .8;
pin_extrusion = 1.6;

base_height = 1;
base_pad = .5;
dot_to_arm_pad = .5;
hole_radius_pad = .3;
hole_depth_pad = .3;

arm_width = 2.5;
arm_side_pad = 1;
arm_top_pad = 1;

rotate([0, 0, 45]) translate([0, 0, base_height+dot_radius+base_pad]) rotate([360*$t, 0, 0])
//translate([20, 0, .5/2])
union() {
    translate([0, 0, -(dot_thiccness)/2]) cylinder(dot_thiccness, r=dot_radius, $fn=100);
    cube([(dot_radius*2)+(pin_extrusion*2), pin_width, dot_thiccness], true);
}

base_width = (dot_radius*2)+(dot_to_arm_pad*2)+(sqrt(arm_width*2));

translate([-base_width/2, -base_width/2, 0])
    cube([
        base_width,
        base_width,
        base_height,
    ]);

for (i = [0, 180]) {
    intersection() {
        rotate([0, 0, 45-i]) union() {
            difference() {
                translate([dot_radius+dot_to_arm_pad, -arm_width/2 - dot_to_arm_pad/2, base_height])
                    cube([arm_width, arm_width+dot_to_arm_pad, dot_radius+base_pad+(pin_width/2)+arm_top_pad]);
                translate([dot_radius+pin_extrusion+hole_depth_pad, 0, base_height+dot_radius+base_pad])
                    rotate([0, -90, 0])
                    cylinder(inf, r=(pin_width/2)+hole_radius_pad, $fn=100);
            }
        }

        translate([-base_width/2, -base_width/2, 0]) cube([base_width, base_width, 100]);
    }
}
