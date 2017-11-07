%%

import brains_analysis.gaze.process.get_projected_positions_and_origins;
import brains_analysis.gaze.process.align_edf_matrices;
import brains_analysis.util.general.extract_field;
import brains_analysis.io.get_rois;
import brains_analysis.process.roi_file_to_container;
import brains_analysis.process.get_in_bounds_index;
import brains_analysis.process.add_pair_id;

conf = brains_analysis.config.load();
brains_analysis.util.general.add_depends( conf );
io = h5_api();

%%

sessions = { '110217' };

save_p = fullfile( conf.PATHS.data.root, conf.PATHS.data.free_viewing, 'processed', 'edf' );

h5_file = fullfile( save_p, 'raw_positions.h5' );
io.require_file( h5_file );
io.h5_file = h5_file;
io.require_group( '/Position' );

col_key = { 'position_x', 'positon_y', 'origin_x', 'origin_y', 'time' };

for i = 1:numel(sessions)

  edfs = brains_analysis.io.get_edfs( conf, sessions{i} );
  edfs = add_pair_id( edfs );
  distances = brains_analysis.io.get_distances( conf, sessions{i} );

  proj_edfs = get_projected_positions_and_origins( edfs, distances );

  aligned_edfs = align_edf_matrices( proj_edfs );

  pos = extract_field( aligned_edfs, 'projected_position' );
  time = extract_field( aligned_edfs, 'time' );
  origins = extract_field( aligned_edfs, 'origin_other_rel_self' );

  combined = pos;
  combined.data = [ pos.data, origins.data, time.data ];
  
  io.add( combined, '/Position' );  
end

%%

rois = roi_file_to_container( get_rois() );

%%

% subset = combined.only( {'pair_id__1'} );
subset = combined;
% subset.data(:, 2) = subset.data(:, 2) - 10;
in_bounds = get_in_bounds_index( subset, rois.only('face') );

%%

pair_id = 'pair_id__7';

monk1 = in_bounds.only( { pair_id, 'kuro'} );
monk2 = in_bounds.only( { pair_id, 'ephron'} );

assert( ~isempty(monk1) && ~isempty(monk2), 'No data matched.' );

m1_lab = char( monk1('monkey') );
m2_lab = char( monk2('monkey') );

figure(1); clf();
ax(1) = subplot( 1, 2, 1 );
plot( monk1.data(:, 1), monk1.data(:, 2), 'k*', 'markersize', .1 );
inb1 = monk1.data(:, 6) == 1;
hold on;
plot( monk1.data(inb1, 1), monk1.data(inb1, 2), 'r*', 'markersize', .1 );

title( sprintf('%s looks to %s', m1_lab, m2_lab) );

ax(2) = subplot( 1, 2, 2 );
plot( monk2.data(:, 1), monk2.data(:, 2), 'k*', 'markersize', .1 );
inb2 = monk2.data(:, 6) == 1;
hold on;
plot( monk2.data(inb2, 1), monk2.data(inb2, 2), 'r*', 'markersize', .1 );

title( sprintf('%s looks to %s', m2_lab, m1_lab) );

set( ax, 'xlim', [-150, 150] );
set( ax, 'ylim', [-100, 100] );
