import brains_analysis.process.add_pair_id;
import brains_analysis.io.get_plex_starts;
import brains_analysis.io.get_gaze_times;
import brains_analysis.io.get_rois;
import brains_analysis.process.roi_file_to_container;
import shared_utils.io.dirnames;
import shared_utils.io.require_dir;

conf = brains_analysis.config.load();
root_p = conf.PATHS.data.root;
save_p = fullfile( root_p, 'free_viewing', 'processed', 'edf' );
require_dir( save_p );

rois = roi_file_to_container( get_rois() );

plex_starts = add_pair_id( get_plex_starts() );

gaze_times = get_gaze_times( conf, rois, plex_starts.pcombs({'date', 'session'}) );
gaze_times = add_pair_id( gaze_times );

save( fullfile(save_p, 'gaze_times.mat'), 'gaze_times' );