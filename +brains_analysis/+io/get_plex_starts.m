function starts = get_plex_starts(conf, session_dirs)

import shared_utils.io.dirnames;
import shared_utils.assertions.*;
import shared_utils.cell.ensure_cell;
import brains_analysis.process.meta_file_to_labels;
import brains_analysis.util.io.try_json_decode;
import brains_analysis.process.get_plex_events;
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

starts = Container();

for i = 1:numel(session_dirs)
  
  sesh_dir = session_dirs{i};
  validate__session_folder( sesh_dir );
  
  meta_file_path = fullfile( sesh_dir, 'mat', 'meta.json' );
  pl2_file = dirnames( fullfile(sesh_dir, 'plex'), '.pl2', true );
  pl2_file = pl2_file{1};
  
  meta_file = try_json_decode( meta_file_path );
  meta_labels = meta_file_to_labels( meta_file );
  
  start = get_plex_events( pl2_file, {'AI02'}, 'AI02' );
  
  if ( all(meta_labels.contains({'110317', 'session__2'})) )
    fprintf( ['\n\nWARNING: Manually removing offending start times from' ...
      , ' 110317 / session 2.'] );
    assert( numel(start) == 12 );
    ind = [ false; diff(start)/1e3 < 300 ];
    assert( sum(ind) == 4 );
    start( ind ) = [];
  end
  
  cont = Container( start, meta_labels.repeat(numel(start)) );
  cont = cont.require_fields( 'edf_filenumber' );
  pair_ids = arrayfun( @(x) ['edf_filenumber__', num2str(x)], 1:numel(start), 'un', false );
  
  cont( 'edf_filenumber' ) = pair_ids;
  
  starts = starts.append( cont );
end

end