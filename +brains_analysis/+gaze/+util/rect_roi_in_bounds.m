function in_bounds = rect_roi_in_bounds(pos, rect)

%   RECT_ROI_IN_BOUNDS -- Return whether coordinates are within a given
%     rect bounds.
%
%     IN:
%       - `pos` (double) -- Coordinates. Mx2 matrix of [x, y] positions.
%       - `rect` (double) -- Boundaries. 1x4 vector of [min_x, min_y,
%         max_x, max_y] coordinates.
%     OUT:
%       - `in_bounds` (logical)

import shared_utils.assertions.*;

assert__m_dimension_size_n( pos, 2, 2, 'the position matrix' );
assert__numel( rect, 4, 'the roi bounds' );

in_x = pos(:, 1) >= rect(1) & pos(:, 1) <= rect(3);
in_y = pos(:, 2) >= rect(2) & pos(:, 2) <= rect(4);

in_bounds = in_x & in_y;


end