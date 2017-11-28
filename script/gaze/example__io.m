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

sessions = { '112117_1' };

brains_analysis.io.add_processed_positions( conf, sessions );

%%  LOAD

key = pos_io.read( '/Key' );
pos = pos_io.read( '/Position' );

% key = shared_utils.io.fload( fullfile('H:\brains\free_viewing\raw\112117_1', 'key.mat') );
% pos = shared_utils.io.fload( fullfile('H:\brains\free_viewing\raw\112117_1', 'positions.mat') );

%%  bounds

rois = roi_file_to_container( get_rois() );

jess = rois({'siqi'}); 
jess('monkey') = 'jessica';
rois = append( rois, jess );

% rois.data(:, 2) = rois.data(:, 2) - 1e3;
% rois.data(:, 4) = rois.data(:, 4) + 1e3;

subset = pos;
[in_bounds, bounds_key] = get_in_bounds_index( subset, rois({'eyes'}), key );

%%

m1 = in_bounds.only( {'pair_id__1', 'siqi'} );
m2 = in_bounds.only( {'pair_id__1', 'jessica'} );

n_samples = 1000;

figure(1); clf();
subplot( 2, 1, 1 );
m1_bounds = m1.data( :, strcmp(bounds_key, 'in_bounds') );
m2_bounds = m2.data( :, strcmp(bounds_key, 'in_bounds') );
inds_m1 = find_logical_starts( m1_bounds == 1, n_samples );
inds_m2 = find_logical_starts( m2_bounds == 1, n_samples );
m1_bounds(:) = 0;
m2_bounds(:) = 0;
for i = 1:numel(inds_m1)
  m1_bounds( inds_m1(i):inds_m1(i)+n_samples-1 ) = 1;
end
for i = 1:numel(inds_m2)
  m2_bounds( inds_m2(i):inds_m2(i)+n_samples-1 ) = 1;
end

stop = 1 * 60 * 1000;

x = 1:stop;

plot( x, m1_bounds(x), 'r' );

subplot( 2, 1, 2 );
plot( x, m2_bounds(x), 'b' );


%%

m1 = in_bounds.only( {'pair_id__1', 'siqi'} );
m2 = in_bounds.only( {'pair_id__1', 'jessica'} );

eg__position_plot( m1, m2, bounds_key );

%%

m1_bounds = m1.data( :, strcmp(bounds_key, 'in_bounds') );
m2_bounds = m2.data( :, strcmp(bounds_key, 'in_bounds') );

mutual = m1_bounds & m2_bounds;

mutual_indices = find_logical_starts( mutual, 3 );

mutual_times = m1.data( mutual_indices, strcmp(bounds_key, 'time') );





