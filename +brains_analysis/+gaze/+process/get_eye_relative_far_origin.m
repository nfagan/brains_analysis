function origin = get_eye_relative_far_origin( m1_dists_to_screen_cm, m2_dists_to_screen_cm, screen_dims_cm )

%   GET_EYE_RELATIVE_FAR_ORIGIN -- Get the (left, bottom) origin of a
%     far-plane roi, relative to the near-plane eye.
%
%     IN:
%       - `m1_dists_to_screen_cm` (double) -- 3-element vector specifying
%         [x, y, z] distances to the screen, in cm. x is the distance to
%         the left-edge of the screen; y is distance from the top of the
%         screen to the eye, such that eye-positions above the top of the
%         screen are negative.
%       - `m2_dists_to_screen_cm` (double) -- 3-element vector, same as for
%         m1. Note that the left-edge is *m2's left-edge*; i.e., m1's right
%         edge.
%       - `screen_dims_cm` (double) -- 2-element vector specifying [width,
%         height] of the monitor, in cm.
%     OUT:
%       - `origin` (double) -- 2-element [x, y] position.

import shared_utils.assertions.*;

assert__numel( m1_dists_to_screen_cm, 3 );
assert__numel( m2_dists_to_screen_cm, 3 );
assert__numel( screen_dims_cm, 2 );

screen_width_cm = screen_dims_cm(1);

eye_rel_left = screen_width_cm - (m2_dists_to_screen_cm(1) + m1_dists_to_screen_cm(1));
eye_rel_bottom = m1_dists_to_screen_cm(2) - m2_dists_to_screen_cm(2);

origin = [ eye_rel_left, eye_rel_bottom ];

end