function self = match_pair_id_to_other(self, other)

import shared_utils.assertions.*;

assert__isa( self, 'Container' );
assert__isa( other, 'Container' );

required_fields = { 'session', 'date', 'edf_filenumber', 'pair_id' };
assert( all(self.contains_fields(required_fields)) && all(other.contains_fields(required_fields)) ...
  , 'Required fields ''%s'' are not present in all objects.', strjoin(required_fields, ', ') );

[I, C] = self.get_indices( {'session', 'date', 'edf_filenumber'} );

other_pair_ids = other( 'pair_id', : );

for i = 1:numel(I)
  matching_other = other.where( C(i, :) );
  assert( sum(matching_other) == 1, ['Too many or too few elements matched' ...
    , ' the combination ''%s''.'], strjoin(C(i, :), ', ') );
  
  pair_id_other = other_pair_ids( matching_other );
  
  self( 'pair_id', I{i} ) = pair_id_other;
end


end