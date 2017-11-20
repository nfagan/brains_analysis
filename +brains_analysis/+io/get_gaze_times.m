function all_times = get_gaze_times(conf, rois, cmbs)

%   GET_GAZE_TIMES -- Get time-stamps of mutual and exclusive gaze.
%
%     IN:
%       - `conf` (struct, []) 
%       - `rois` (Container, [])
%       - `cmbs` (cell array of strings)
%     OUT:
%       - `all_times` (Container)

import shared_utils.assertions.*;
import brains_analysis.util.assertions.assert__is_config;
import brains_analysis.io.get_fv_h5;
import brains_analysis.io.get_rois;
import brains_analysis.process.add_pair_id;
import brains_analysis.process.roi_file_to_container;
import brains_analysis.process.get_in_bounds_index;
import brains_analysis.util.general.find_logical_starts;

if ( nargin < 1 || isempty(conf) )
  conf = brains_analysis.config.load(); 
end
if ( nargin < 2 || isempty(rois) )
  rois = roi_file_to_container( get_rois() );
end

assert__is_config( conf );
assert__is_cellstr( cmbs );
assert__isa( rois, 'Container' );

io = get_fv_h5( conf, fullfile('edf', 'raw_positions.h5') );

key = io.read( '/Key' );

all_times = Container();

for i = 1:size(cmbs, 1)
  fprintf( '\nProcessing %s (%d of %d)', strjoin(cmbs(i, :), ', '), i, size(cmbs, 1) );
  dat = io.read( '/Position', 'only', cmbs(i, :) );
  dat = add_pair_id( dat );
  [in_bounds, bounds_key] = get_in_bounds_index( dat, rois, key );
  
  C = in_bounds.pcombs( {'roi', 'pair_id'} );
  
  for j = 1:size(C, 1)    
    fprintf( '\n\tProcessing %s (%d of %d)', strjoin(C(j, :), ', '), j, size(C, 1) );
    subset = in_bounds(C(j, :));
    subset = subset.require_fields( {'gaze_type', 'initiator'} );
    
    monks = subset('monkey');
    
    assert( numel(monks) == 2, 'Too many or too few monkeys.' );
  
    m1 = subset(monks(1));
    m2 = subset(monks(2));

    m1_in = m1.data(:, strcmp(bounds_key, 'in_bounds')) == 1;
    m2_in = m2.data(:, strcmp(bounds_key, 'in_bounds')) == 1;

    mutual_starts = find_logical_starts( m1_in & m2_in, 3 );
    m1_starts = find_logical_starts( m1_in, 3 );
    m2_starts = find_logical_starts( m2_in, 3 );
    
    if ( ~isempty(mutual_starts) )
      mutual_times = m1.data(mutual_starts, strcmp(bounds_key, 'time'));
      mutual_times = mutual_times ./ 1e3;
      init = find_initiated( mutual_starts, m1_in, m2_in );
      pairs_mutual = field_label_pairs( one(subset) );
      cont_mutual = Container( mutual_times, pairs_mutual{:} );
      cont_mutual('monkey') = strjoin( monks, '_' );
      cont_mutual('gaze_type') = 'gaze_type__mutual';
      cont_mutual('initiator') = 'initiator__null';
      cont_mutual('initiator', init == 1) = sprintf( 'initiator__%s', monks{1} );
      cont_mutual('initiator', init == 0) = sprintf( 'initiator__%s', monks{2} );
      all_times = all_times.append( cont_mutual );
    end
    
    if ( ~isempty(m1_starts) )
      m1_times = m1.data(m1_starts, strcmp(bounds_key, 'time'));
      m1_times = m1_times ./ 1e3;
      pairs_m1 = field_label_pairs( one(m1) );
      cont_m1 = Container( m1_times, pairs_m1{:} );
      cont_m1('gaze_type') = 'gaze_type__exclusive';
      cont_m1('initiator') = 'initiator__null';
      
      all_times = all_times.append( cont_m1 );
    end
    
    if ( ~isempty(m2_starts) )
      m2_times = m2.data(m2_starts, strcmp(bounds_key, 'time'));
      m2_times = m2_times ./ 1e3; 
      pairs_m2 = field_label_pairs( one(m2) );
      cont_m2 = Container( m2_times, pairs_m2{:} );
      cont_m2('gaze_type') = 'gaze_type__exclusive';
      cont_m2('initiator') = 'initiator__null';
      
      all_times = all_times.append( cont_m2 );
    end
  end
end

end

function init = find_initiated(mutual_starts, m1_in, m2_in)

init = nan( size(mutual_starts) );

for i = 1:numel(mutual_starts)
  
  j = mutual_starts(i) - 1;
  
  if ( j > 0 && m1_in(j) )
    init(i) = 0;
  end
  if ( j > 0 && m2_in(j) )
    assert( isnan(init(i)) );
    init(i) = 1;
  end
end

end