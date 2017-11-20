function all_rebuilt = add_tile_id(obj, n_tiles, habit_within)

import shared_utils.assertions.*;

assert__isa( obj, 'Container' );
assert__isa( n_tiles, 'double' );
assert__is_scalar( n_tiles );

if ( nargin < 3 )
  habit_within = { 'unit_id', 'gaze_type', 'roi', 'monkey' };
else
  assert__is_cellstr_or_char( habit_within );
end
unit_indices = obj.get_indices( habit_within );

all_rebuilt = Container();

for i = 1:numel(unit_indices)
  subset = obj(unit_indices{i});
  rebuilt = Container();
  pair_ids = subset( 'pair_id' );
  assert( all(cellfun(@(x) ~isempty(strfind(x, 'pair_id__')), pair_ids)), 'Bad format.' );
  pair_id_numbers = cellfun( @(x) str2double(x(numel('pair_id__')+1:end)), pair_ids );
  [~, sorted_ind] = sort( pair_id_numbers );
  pair_ids = pair_ids( sorted_ind );
  for j = 1:numel(pair_ids)
    rebuilt = append(rebuilt, subset(pair_ids(j)));
  end
  
  rebuilt = rebuilt.require_fields( 'tile_id' );
  
  n_per_bin = floor( rebuilt.shape(1) / n_tiles );
  stp = 1;
  iter = 1;
  while ( stp < rebuilt.shape(1) && iter <= n_tiles )
    if ( iter < n_tiles )
      ind = stp:stp+n_per_bin-1;
    else
      ind = stp:rebuilt.shape(1);
    end
    rebuilt('tile_id', ind) = sprintf( 'tile_id__%d', iter );
    iter = iter + 1;
    stp = stp + n_per_bin;
  end
  
  all_rebuilt = all_rebuilt.append( rebuilt );
end



end