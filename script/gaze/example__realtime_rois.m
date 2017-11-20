
dist_file = brains_analysis.util.io.try_json_decode( 'C:\Users\changLab\Desktop\distances_1.json' );
roi_file = brains_analysis.util.io.try_json_decode( 'H:\brains\free_viewing\raw\rois.json' );
screen_constants = brains_analysis.gaze.util.get_screen_constants();

roi_m2_relative_m1 = roi_file.ephron;
roi_m1_relative_m2 = roi_file.kuro;

pos = [1500, -100];

[pos_m1_on_m2, origin_m2] = ...
  brains_analysis.gaze.process.get_projected_position_and_origin( dist_file.m1, dist_file.m2, pos, screen_constants );

rois_m2_rel_m1 = fieldnames( roi_m2_relative_m1 );
roi_bounds_m2_relative_m1 = struct();
for i = 1:numel(rois_m2_rel_m1)
  roi_name = rois_m2_rel_m1{i};
  bounds = roi_m2_relative_m1.(roi_name);
  bounds([1, 3]) = bounds([1, 3]) + origin_m2(1);
  bounds([2, 4]) = bounds([2, 4]) + origin_m2(2);
  roi_bounds_m2_relative_m1.(roi_name) = bounds;
end


