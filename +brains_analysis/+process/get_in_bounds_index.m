function [all_in_bounds, new_key] = get_in_bounds_index( pos, rois, key, bounds_func )

import shared_utils.assertions.*;

if ( nargin < 4 )
  bounds_func = @brains_analysis.gaze.util.rect_roi_in_bounds;
end

assert__isa( pos, 'Container', 'the position' );
assert__isa( rois, 'Container', 'the rois' );
assert__is_cellstr( key, 'the column-key' );
assert__isa( bounds_func, 'function_handle' );

assert__isa( pos.data, 'double' );
assert__isa( rois.data, 'double' );

assert__m_dimension_size_n( pos.data, 2, 5 );
assert__m_dimension_size_n( rois.data, 2, 4 );

required_keys = { 'position_x' 'position_y', 'origin_x', 'origin_y' };
assert( numel(key) == shape(pos, 2), ['The number of elements in the key' ...
  , ' (%d) does not match the number of columns of data (%d)'] ...
  , numel(key), shape(pos, 2) );
assert( isempty(setdiff(required_keys, key)), 'At least one required key is missing.' );

inds_within = { 'date', 'session' };

[I, C] = pos.get_indices( inds_within );

all_in_bounds = Container();
new_key = [ key(:)', 'in_bounds' ];

for i = 1:numel(I)
  subset_labs = pos.labels.keep(I{i});
  monks = subset_labs.flat_uniques( 'monkey' );
  
  assert__numel( monks, 2, 'the monkey labels' );
  
  assert( all(rois.contains(monks)), 'No rois matched the current monkeys.' );
  
  for k = 1:2
    own_index = I{i} & pos.where( monks{1} );
    own_position = pos.data( own_index, : );
    other_monk = monks{2};
    
    [roi_inds, roi_cmbs] = get_indices( only(rois, other_monk), 'roi' );
    
    for j = 1:numel(roi_inds)
      roi = rois.data( roi_inds{j}, : );
      ox_ind = find( strcmp(key, 'origin_x') );
      oy_ind = find( strcmp(key, 'origin_y') );
      px_ind = find( strcmp(key, 'position_x') );
      py_ind = find( strcmp(key, 'position_y') );
      origin = own_position( 1, [ox_ind, oy_ind] );
      
      roi(1) = roi(1) + origin(1);
      roi(3) = roi(3) + origin(1);
      roi(2) = roi(2) + origin(2);
      roi(4) = roi(4) + origin(2);
      
      in_bounds = bounds_func( own_position(:, [px_ind, py_ind]), roi );
      
      current_cont = pos(own_index);
      current_cont = current_cont.require_fields( 'roi' );
      current_cont( 'roi' ) = roi_cmbs{j, 1};      
      current_cont.data = [ own_position, in_bounds ];
      
      all_in_bounds = all_in_bounds.append( current_cont );
    end
    
    monks = fliplr( monks );
  end
end

end