function [pos_m1_on_m2, origin] = get_projected_position_and_origin(m1, m2, pos)

import brains_analysis.gaze.process.*;
import brains_analysis.gaze.util.*;
import shared_utils.assertions.*;

required_fields = { 'eye_to_ground_cm', 'eye_to_monitor_left_cm', 'eye_to_monitor_front_cm' };
assert__isa( m1, 'struct' );
assert__isa( m2, 'struct' );
assert__isa( pos, 'double' );
assert__are_fields( m1, required_fields );
assert__are_fields( m2, required_fields );

screen_const = get_screen_constants();

screen_rect_px = screen_const.SCREEN_RECT_PX;
screen_dims_cm = [ screen_const.SCREEN_WIDTH_CM, screen_const.SCREEN_HEIGHT_CM ];
inter_monitor_cm = screen_const.DISTANCE_BETWEEN_SCREENS_CM;
screen_top_to_ground_cm = screen_const.DISTANCE_SCREEN_TOP_TO_GROUND_CM;

m1_eye_to_ground_cm = m1.eye_to_ground_cm;
m1_eye_to_monitor_left_cm = m1.eye_to_monitor_left_cm;
m1_eye_to_monitor_front_cm = m1.eye_to_monitor_front_cm;

m2_eye_to_ground_cm = m2.eye_to_ground_cm;
m2_eye_to_monitor_left_cm = m2.eye_to_monitor_left_cm;
m2_eye_to_monitor_front_cm = m2.eye_to_monitor_front_cm;

m1_eye_to_monitor_top_cm = screen_top_to_ground_cm - m1_eye_to_ground_cm;
m2_eye_to_monitor_top_cm = screen_top_to_ground_cm - m2_eye_to_ground_cm;

m1_dists_to_screen_cm = [ m1_eye_to_monitor_left_cm, m1_eye_to_monitor_top_cm, m1_eye_to_monitor_front_cm ];
m2_dists_to_screen_cm = [ m2_eye_to_monitor_left_cm, m2_eye_to_monitor_top_cm, m2_eye_to_monitor_front_cm ];

z_far_cm = m2_eye_to_monitor_front_cm + m1_eye_to_monitor_front_cm + inter_monitor_cm;
origin = get_eye_relative_far_origin( m1_dists_to_screen_cm, m2_dists_to_screen_cm, screen_dims_cm );

pos_m1_on_m2 = zeros( size(pos) );

for i = 1:size(pos, 1)
  pos_m1_on_m2(i, :) = get_projected_position( pos(i, :), screen_rect_px, screen_dims_cm, m1_dists_to_screen_cm, z_far_cm );
end

end