function all_data = get_neural_data(conf, units)

import brains_analysis.util.assertions.assert__is_config;
import brains_analysis.util.validate.validate__session_folder;
import shared_utils.assertions.*;
import shared_utils.io.dirnames;

if ( isempty(conf) ), conf = brains_analysis.config.load(); end

assert__is_config( conf );

assert__isa( units, 'Container', 'the unit specifiers' );

data_p = fullfile( conf.PATHS.data.root, 'free_viewing', 'raw' );

units = units.require_fields( 'unit_n' );

units_within = { 'date', 'session' };
[I, sessions] = units.get_indices( units_within );

all_data = cell( shape(units, 1), 1 );
labs = SparseLabels();
stp = 1;

for i = 1:numel(I)
  fprintf( '\n Loading ''%s'' (%d of %d)', strjoin(sessions(i, :), ', '), i, numel(I) );
  
  sesh = sessions{i, strcmp(units_within, 'session')};
  date = sessions{i, strcmp(units_within, 'date')};
  
  assert( ~isempty(strfind(sesh, 'session__')), 'Wrong format for session labels.' );
  sesh_n = str2double( sesh(numel('session__')+1:end) );
  assert( ~isnan(sesh_n), 'Wrong forma for session number.' );
  folder_id = sprintf( '%s_%d', date, sesh_n );
  
  sesh_dir = fullfile( data_p, folder_id );
  
  validate__session_folder( sesh_dir );
  
  pl2 = dirnames( fullfile(sesh_dir, 'plex'), '.pl2', true );
  pl2 = pl2{1};
  
  subset = units( I{i} );
  
  channel_types = subset( 'channel_type', : );
  channels = subset( 'channel', : );
  
  for j = 1:shape(subset, 1)
    if ( strcmp(channel_types{j}, 'lfp') )
      func = @PL2Ad;
      inputs = { pl2, channels{j} };
    elseif ( strcmp(channel_types{j}, 'spike') )
      func = @PL2Ts;
      inputs = { pl2, channels{j}, subset.data(j) };
    else
      error( 'Unrecognized channel_type ''%s''.', channel_types{j} );
    end
    
    all_data{stp} = func( inputs{:} );
    current_labs = subset(j).labels;
    current_labs = current_labs.set_field( 'unit_n', sprintf('unit__%s', num2str(subset.data(j))) );
    labs = labs.append( current_labs );    
    
    stp = stp + 1;
  end
end

all_data = Container( all_data, labs );

end