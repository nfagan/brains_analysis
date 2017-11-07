function proj_positions = get_projected_positions_and_origins( positions, distances )

import shared_utils.assertions.*;
import brains_analysis.gaze.process.get_projected_position_and_origin;

assert__isa( positions, 'Container', 'the position data' );
assert__isa( distances, 'Container', 'the distance data' );
assert__isa( positions.data, 'struct', 'the position data' );
assert__isa( distances.data, 'struct', 'the position data' );

pos_sesh = positions.pcombs( {'date', 'session'} );

for i = 1:size(pos_sesh, 1)
  assert( any(distances.where(pos_sesh(i, :))) ...
    , [ 'The session x date combination ''%s'', present in the position' ...
    , ' Container, was not present in the distances Container.'] ...
    , strjoin(pos_sesh(i, :), ', ') );
end

proj_positions = Container();

for i = 1:size(pos_sesh, 1)
  fprintf( '\n Processing %d of %d', i, size(pos_sesh, 1) );
  
  session_comb = pos_sesh(i, :);
  
  edfs_this_sesh = positions.uniques_where( 'edf_filename', session_comb );
  distance = distances.only( pos_sesh(i, :) );
  
  assert__m_dimension_size_n( distance.data, 1, 2, 'the distances' );
  
  for k = 1:numel(edfs_this_sesh)
    fprintf( '\n\t Processing %d of %d', k, numel(edfs_this_sesh) );
    
    edf_file = edfs_this_sesh{k};
    current_edf = positions.only( [session_comb, edf_file] );
    assert__m_dimension_size_n( current_edf.data, 1, 1, 'the position data' );
    
    other_monk = setdiff( distance('monkey'), current_edf('monkey') );
    assert__numel( other_monk, 1, 'the number of monkeys' );
    
    own_distance = distance.only( current_edf('monkey') );
    other_distance = distance.only( other_monk );
    own_distance = own_distance.data;
    other_distance = other_distance.data;
    
    all_edf_data = current_edf.data;
    position = all_edf_data.position;
    
    [pos_self_on_other, origin_other_rel_self] = ...
      get_projected_position_and_origin( own_distance, other_distance, position );
    
    all_edf_data.projected_position = pos_self_on_other;
    all_edf_data.origin_other_rel_self = ...
      repmat( origin_other_rel_self, size(pos_self_on_other, 1), 1 );
    
    current_edf.data = all_edf_data;
    proj_positions = append( proj_positions, current_edf );
  end
end

end