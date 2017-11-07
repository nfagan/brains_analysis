function edfs = get_edfs(conf, session_dirs)

%   GET_EDFS -- Get free viewing data stored in .edf files.
%
%     IN:
%       - `conf` (struct) |OPTIONAL| -- Config file.
%     OUT:
%       - `edfs` (Container)

import shared_utils.io.dirnames;
import shared_utils.assertions.*;
import shared_utils.cell.ensure_cell;
import brains_analysis.util.validate.validate__session_folder;
import brains_analysis.process.meta_file_to_labels;
import brains_analysis.util.io.try_json_decode;

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

edfs = Container();

for i = 1:numel(session_dirs)
  
  fprintf( '\nProcessing ''%s'' (%d of %d)', session_dirs{i}, i, numel(session_dirs) );
  
  sesh_dir = session_dirs{i};
  
  validate__session_folder( sesh_dir );
  
  mat_dir = fullfile( sesh_dir, 'mat' );
  edf_dir_m1 = fullfile( sesh_dir, 'edf', 'm1' );
  edf_dir_m2 = fullfile( sesh_dir, 'edf', 'm2' );
  meta_file = fullfile( mat_dir, 'meta.json' );
  meta_file = try_json_decode( meta_file );
  meta_labels = meta_file_to_labels( meta_file );
  
  edf_files_m1 = dirnames( edf_dir_m1, '.edf', false );
  edf_files_m2 = dirnames( edf_dir_m2, '.edf', false );
  
  edfs_m1 = process_edfs( edf_dir_m1, edf_files_m1, meta_labels );
  edfs_m2 = process_edfs( edf_dir_m2, edf_files_m2, meta_labels );
  
  edfs_m1 = edfs_m1.require_fields( 'monkey' );
  edfs_m1( 'monkey' ) = meta_file.m1;
  edfs_m2 = edfs_m2.require_fields( 'monkey' );
  edfs_m2( 'monkey' ) = meta_file.m2;
  
  edfs = edfs.extend( edfs_m1, edfs_m2 );
end

end

function edfs = process_edfs(edf_dir, edf_filenames, meta_labels)

edfs = Container();

for i = 1:numel(edf_filenames)  
  edf_file = edf_filenames{i};
  edf = Edf2Mat( fullfile(edf_dir, edf_file) );
  
  data = struct();

  data.position = [ edf.Samples.posX, edf.Samples.posY ];
  data.time = edf.Samples.time;
  data.sync_index = find( strcmpi(edf.Events.Messages.info, 'SYNCH') );
  assert( numel(data.sync_index) == 1, ['Expected to find one ''SYNCH''' ...
    , ' message in edf file ''%s''; instead %d were present.'] ...
    , edf_file, numel(data.sync_index) );

  data.start_time = edf.Events.Messages.time( data.sync_index );
  data.start_index = find( data.time == data.start_time );
  
  assert( ~isempty(data.start_index), 'No start time found??' );
  
  edf_cont = Container( data, meta_labels );
  
  edf_file_number = str2double( edf_file(isstrprop(edf_file, 'digit')) );
  assert( ~isnan(edf_file_number) && rem(edf_file_number, 1) == 0 ...
    , 'Invalid edf file number for edf file ''%s''.' ...
    , edf_file );
  
  edf_cont = edf_cont.require_fields( {'edf_filename', 'edf_filenumber'} );
  edf_cont( 'edf_filename' ) = edf_file;
  edf_cont( 'edf_filenumber' ) = sprintf( 'edf_filenumber__%d', edf_file_number );
  
  edfs = append( edfs, edf_cont );
end


end