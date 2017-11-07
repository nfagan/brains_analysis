function labs = meta_file_to_labels(s)

%   META_FILE_TO_LABELS -- Convert a meta-file struct to a SparseLabels
%     object.
%
%     IN:
%       - `s` (struct)
%     OUT:
%       - `labs` (SparseLabels)

import shared_utils.assertions.*;

required_fields = { 'date', 'session', 'm1', 'm2' };

assert__isa( s, 'struct', 'the meta file' );
assert__are_fields( s, required_fields );

structfun( @(x) assert__isa(x, 'char'), s );

s.m1 = [ 'm1__', s.m1 ];
s.m2 = [ 'm2__', s.m2 ];

s = structfun( @(x) {x}, s, 'un', false );

labs = SparseLabels( s );

end