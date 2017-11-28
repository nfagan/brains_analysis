function edfs = align_edf_matrices( edfs )

%   ALIGN_EDF_MATRICES -- For each m1 x m2 pair of .edf files, ensure the
%     position, time, and projected position matrices are of the same
%     dimensions, and begin at the same time point.
%
%     IN:
%       - `edfs` (Container)
%     OUT:
%       - `edfs` (Container)

import shared_utils.assertions.*;

assert__isa( edfs, 'Container' );
assert__isa( edfs.data, 'struct' );
assert__are_fields( edfs.data, {'projected_position', 'origin_other_rel_self'} );

[I, C] = edfs.get_indices( { 'date', 'session', 'edf_filenumber'} );

fields_to_resize = { 'position', 'projected_position', 'origin_other_rel_self', 'time' };

for i = 1:numel(I)
  
  subset = edfs( I{i} );
  assert__m_dimension_size_n( subset.data, 1, 2 );
  
  first = subset(1);
  sec = subset(2);
  
  dat1 = first.data;
  dat2 = sec.data;
  
  start1 = dat1.start_index;
  start2 = dat2.start_index;
  
  assert( dat1.time(start1) == dat1.start_time, 'Start times must match!' );
  assert( dat2.time(start2) == dat2.start_time, 'Start times must match!' );
  
  sz1 = size( dat1.(fields_to_resize{1}), 1 );
  sz2 = size( dat2.(fields_to_resize{1}), 1 );
  
  for k = 2:numel(fields_to_resize)
    msg = 'Sizes must match across resize fields.';
    assert( size(dat1.(fields_to_resize{k}), 1) == sz1, msg );
    assert( size(dat2.(fields_to_resize{k}), 1) == sz2, msg );
  end
  
  for k = 1:numel(fields_to_resize)
    dat1.(fields_to_resize{k}) = dat1.(fields_to_resize{k})(start1:end, :);
    dat2.(fields_to_resize{k}) = dat2.(fields_to_resize{k})(start2:end, :);
  end
  
  sz1 = size( dat1.position, 1 );
  sz2 = size( dat2.position, 1 );
  
  new_sz = sz1;
  
  if ( sz1 > sz2 )
    new_sz = sz2;
  elseif ( sz2 > sz1 )
    new_sz = sz1;
  end
  
  for k = 1:numel(fields_to_resize)
    dat1.(fields_to_resize{k}) = dat1.(fields_to_resize{k})(1:new_sz, :);
    dat2.(fields_to_resize{k}) = dat2.(fields_to_resize{k})(1:new_sz, :);
  end
  
  %   make time relative to 0.
  dat1.time = dat1.time - dat1.time(1);
  dat2.time = dat2.time - dat2.time(1);
  
  edfs.data( I{i} ) = [ dat1; dat2 ];
end

end