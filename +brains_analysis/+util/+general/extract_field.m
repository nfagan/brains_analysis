function out = extract_field(cont, name)

%   EXTRACT_FIELD -- Convert a Container of struct to a Container whose
%     data are a field of that struct.
%
%     IN:
%       - `cont` (Container)
%       - `name` (char)
%     OUT:
%       - `out` (Container)

import shared_utils.assertions.*;

assert__isa( cont, 'Container' );
assert__isa( cont.data, 'struct' );
assert__isa( name, 'char' );
assert__are_fields( cont.data, name );

conts = cell( shape(cont, 1), 1 );

for i = 1:shape(cont, 1)
  current = cont(i);
  dat = current.data;
  unqs = current.field_label_pairs();
  
  conts{i} = Container( dat.(name), unqs{:} );
end

out = Container.concat( conts );

end