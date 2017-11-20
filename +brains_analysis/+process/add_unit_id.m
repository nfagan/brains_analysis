function obj = add_unit_id(obj)

import shared_utils.assertions.*;

assert__isa( obj, 'Container' );

required_fields = { 'unit_n', 'region', 'channel', 'session', 'date' };

assert( all(obj.contains_fields(required_fields)), ['Some of the required' ...
  , ' fields, %s, were not present.'], strjoin(required_fields, ', ') );

I = obj.get_indices( required_fields );
obj = obj.require_fields( {'unit_id'} );

for i = 1:numel(I)
  obj( 'unit_id', I{i} ) = sprintf( 'unit_id__%d', i );
end

end