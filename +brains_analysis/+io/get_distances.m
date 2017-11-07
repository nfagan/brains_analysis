function dists = get_distances(conf, session_dirs)

%   GET_DISTANCES -- Get monitor distances for m1 and m2.
%
%     IN:
%       - `conf` (struct) |OPTIONAL| -- Config file.
%     OUT:
%       - `dists` (Container)

import shared_utils.io.dirnames;
import shared_utils.assertions.*;
import shared_utils.cell.ensure_cell;
import brains_analysis.process.meta_file_to_labels;
import brains_analysis.util.io.try_json_decode;
import brains_analysis.util.validate.validate__session_folder;

if ( nargin < 1 || isempty(conf) ), conf = brains_analysis.config.load(); end

brains_analysis.util.assertions.assert__is_config( conf );

data_dir = fullfile( conf.PATHS.data.root, conf.PATHS.data.free_viewing, 'raw' );

if ( nargin < 2 || isempty(session_dirs) )
  session_dirs = dirnames( data_dir, 'folders', true );
  assert( ~isempty(session_dirs), 'No session subfolders found in ''%s''.', data_dir );
else
  assert__is_cellstr_or_char( session_dirs, 'the sessions' );
  session_dirs = ensure_cell( session_dirs );
  session_dirs = cellfun( @(x) fullfile(data_dir, x), session_dirs, 'un', false );
end

dists = Container();

required_distance_fields = { 'date', 'm1', 'm2' };
required_distance_subfields = { ...
  'name', 'eye_to_ground_cm', 'eye_to_monitor_left_cm' ...
  , 'eye_to_monitor_top_cm', 'eye_to_monitor_front_cm' ...
};

for i = 1:numel(session_dirs)
  
  sesh_dir = session_dirs{i};
  
  validate__session_folder( sesh_dir );
  
  mat_dir = fullfile( sesh_dir, 'mat' );
  
  distance_file = fullfile( mat_dir, 'distances.json' );
  meta_file = fullfile( mat_dir, 'meta.json' );
  
  distances = try_json_decode( distance_file );
  meta_file = try_json_decode( meta_file );
  meta_labels = meta_file_to_labels( meta_file );
  
  try
    assert__are_fields( distances, required_distance_fields );
    assert__are_fields( distances.m1, required_distance_subfields );
    assert__are_fields( distances.m2, required_distance_subfields );
  catch err
    fprintf( '\nFailed to parse distances for ''%s'':', session_dirs{i} );
    throw( err );
  end
  
  dist_m1 = distances.m1;
  dist_m2 = distances.m2;
  
  cont_m1 = Container( distances.m1, meta_labels );
  cont_m1 = cont_m1.require_fields( 'monkey' );
  cont_m1( 'monkey' ) = dist_m1.name;
  
  cont_m2 = Container( distances.m2, meta_labels );
  cont_m2 = cont_m2.require_fields( 'monkey' );
  cont_m2( 'monkey' ) = dist_m2.name;
  
  dists = extend( dists, cont_m1, cont_m2 );
end

end