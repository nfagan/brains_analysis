function add_processed_positions(conf, sessions)

import brains_analysis.gaze.process.get_projected_positions_and_origins;
import brains_analysis.gaze.process.align_edf_matrices;
import brains_analysis.util.general.extract_field;
import brains_analysis.process.roi_file_to_container;
import brains_analysis.process.add_pair_id;
import shared_utils.io.dirnames;
import shared_utils.assertions.*;
import shared_utils.cell.ensure_cell;
import brains_analysis.io.get_edfs;
import brains_analysis.io.get_distances;

if ( nargin < 1 || isempty(conf) ), conf = brains_analysis.config.load(); end

data_dir = fullfile( conf.PATHS.data.root, conf.PATHS.data.free_viewing, 'raw' );
save_p = fullfile( conf.PATHS.data.root, conf.PATHS.data.free_viewing, 'processed', 'edf' );

if ( nargin < 2 )
  sessions = dirnames( data_dir, 'folders', true );
else
  assert__is_cellstr_or_char( sessions );
  sessions = ensure_cell( sessions );
end

io = h5_api();
h5_file = fullfile( save_p, 'raw_positions.h5' );
io.require_file( h5_file );
io.h5_file = h5_file;

pos_path = '/Position';

io.require_group( pos_path );

col_key = { 'position_x', 'position_y', 'origin_x', 'origin_y', 'time' };

io.write( col_key, '/Key' );

for i = 1:numel(sessions)
  session = sessions{i};
  
  fprintf( '\n Processing ''%s'' (%d of %d)', session, i, numel(sessions) );
  
  if ( io.is_container_group(pos_path) && io.contains_labels(sessions{i}, pos_path) )
    fprintf( '\n Skipping ''%s'' because it already exists ... ', session );
    continue;
  end

  edfs = get_edfs( conf, session );
  edfs = add_pair_id( edfs );
  distances = get_distances( conf, session );

  proj_edfs = get_projected_positions_and_origins( edfs, distances );

  aligned_edfs = align_edf_matrices( proj_edfs );

  pos = extract_field( aligned_edfs, 'projected_position' );
  time = extract_field( aligned_edfs, 'time' );
  origins = extract_field( aligned_edfs, 'origin_other_rel_self' );

  combined = pos;
  combined.data = [ pos.data, origins.data, time.data ];
  
  fprintf( '\n Saving ''%s'' ... ', session );
  io.add( combined, '/Position' );  
  fprintf( 'Done.' );
end

end