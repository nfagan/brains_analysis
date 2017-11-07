function pos_cm = get_projected_position(pos_px, screen_rect_px, screen_dims_cm, dists_to_screen_cm, z_far_cm)

%   GET_PROJECTED_POSITION -- Transform near-plane pixel coordinates to
%     far-plane, eye relative real units.
%
%     IN:
%       - `pos_px` (double) -- 2-element x, y position vector in px units,
%         with the screen top-left as origin.
%       - `screen_rect_px` (double) -- 4-element vector specifying the
%         [left, top, right, bottom] corners of the screen, in pixels.
%       - `screen_dims_cm` (double) -- 2-element vector specifying the
%         [width, height] of the screen, in cm.
%       - `dists_to_screen_cm` (double) -- 3-element vector specifying the
%         [x, y, z] distances from the eye to the monitor. x is distance to
%         the left edge of the monitor; y is the distance from the top of 
%         the monitor to the eye, such that eye-positions below the monitor
%         top are positive.
%       - `z_far_cm` (double) -- Distance to the far plane onto which the
%         pixel coordinates will be projected.
%     OUT:
%       - `pos_cm` (double) -- Reprojected coordinates.

import shared_utils.assertions.*;

narginchk( 5, 5 );
assert__numel( pos_px, 2, 'the position' );
assert__numel( screen_rect_px, 4, 'the screen rect in px' );
assert__numel( screen_dims_cm, 2, 'the screen dimensions in cm' );
assert__numel( dists_to_screen_cm, 3, 'the distances to the screen' );
assert__numel( z_far_cm, 1, 'the far z distance' );

screen_fractional_x = pos_px(1) / (screen_rect_px(3) - screen_rect_px(1));
screen_fractional_y = pos_px(2) / (screen_rect_px(4) - screen_rect_px(2));

screen_width_cm = screen_dims_cm(1);
screen_height_cm = screen_dims_cm(2);

screen_dist_x_cm = screen_width_cm * screen_fractional_x;
screen_dist_y_cm = screen_height_cm * screen_fractional_y;

eye_relative_x_cm = screen_dist_x_cm - dists_to_screen_cm(1);
eye_relative_y_cm = dists_to_screen_cm(2) - screen_dist_y_cm;
eye_relative_z_cm = dists_to_screen_cm(3);

projected_x_cm = ( eye_relative_x_cm * z_far_cm ) / eye_relative_z_cm;
projected_y_cm = ( eye_relative_y_cm * z_far_cm ) / eye_relative_z_cm;

pos_cm = [ projected_x_cm, projected_y_cm ];

end