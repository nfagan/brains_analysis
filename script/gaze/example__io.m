import brains_analysis.process.get_in_bounds_index;
import brains_analysis.plot.eg__position_plot;
import brains_analysis.util.general.find_logical_starts;
import brains_analysis.io.get_plex_starts;
import brains_analysis.io.get_rois;
import brains_analysis.process.get_in_bounds_index;
import brains_analysis.process.roi_file_to_container;

%%
conf = brains_analysis.config.load();
brains_analysis.util.general.add_depends( conf );
data_p = conf.PATHS.data;
pos_path = fullfile( data_p.root, data_p.free_viewing, 'processed', 'edf' );
pos_h5 = fullfile( pos_path, 'raw_positions.h5' );

pos_io = h5_api( pos_h5 );

%%  SAVE

sessions = { '110217' };

brains_analysis.io.add_processed_positions( conf, sessions );

%%  LOAD

key = pos_io.read( '/Key' );
pos = pos_io.read( '/Position' );

%%  bounds

rois = roi_file_to_container( get_rois() );
plex_starts = get_plex_starts( conf, sessions );

subset = pos;
[in_bounds, bounds_key] = get_in_bounds_index( subset, rois.only('face'), key );

%%

m1 = in_bounds.only( {'pair_id__2', 'kuro'} );
m2 = in_bounds.only( {'pair_id__2', 'ephron'} );

eg__position_plot( m1, m2, bounds_key );

%%

m1_bounds = m1.data( :, strcmp(bounds_key, 'in_bounds') );
m2_bounds = m2.data( :, strcmp(bounds_key, 'in_bounds') );

mutual = m1_bounds & m2_bounds;

mutual_indices = find_logical_starts( mutual, 3 );

mutual_times = m1.data( mutual_indices, strcmp(bounds_key, 'time') );





