function out = get_screen_constants()

%   GET_SCREEN_CONSTANTS -- Get screen dimensions and other constants.
%
%     OUT:
%       - `out` (struct)

out = struct();
out.SCREEN_RECT_PX = [ 0, 0, 3072, 768 ];
out.SCREEN_WIDTH_CM = 111.3;
out.SCREEN_HEIGHT_CM = 30;
out.DISTANCE_SCREEN_TOP_TO_GROUND_CM = 85.5;
out.DISTANCE_BETWEEN_SCREENS_CM = 17;

end