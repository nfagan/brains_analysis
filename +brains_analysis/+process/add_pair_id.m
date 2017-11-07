function obj = add_pair_id( obj )

%   ADD_PAIR_ID -- Add an identifier for each pair of .edf files.
%
%     IN:
%       - `obj` (Container)
%     OUT:
%       - `obj` (Container)

import shared_utils.assertions.*;

assert__isa( obj, 'Container' );

obj = obj.require_fields( 'pair_id' );

inds_within = { 'date', 'session', 'edf_filenumber' };

[I, C] = obj.get_indices( inds_within );

I = sort_ascending( I, C, inds_within );

for i = 1:numel(I)
  obj( 'pair_id', I{i} ) = sprintf( 'pair_id__%d', i );
end


end

function [I, C] = sort_ascending(I, C, inds_within)

date_ind = strcmp( inds_within, 'date' );
sesh_ind = strcmp( inds_within, 'session' );
edf_ind = strcmp( inds_within, 'edf_filenumber' );

assert( any(date_ind) && any(sesh_ind) && any(edf_ind), 'Incorrect identifiers.' );

dates = C(:, date_ind);
seshs = C(:, sesh_ind);
file_numbers = C(:, edf_ind);

date_ns = datenum( dates, 'mmddyy' );
sesh_ns = parse_int( seshs, 'session__' );
file_ns = parse_int( file_numbers, 'edf_filenumber__' );

new_mat = [ date_ns, sesh_ns, file_ns ];

[~, index] = sortrows( new_mat );

C = C(index, :);
I = I(index);

end

function is = parse_int( col, beginning )

is = zeros( size(col) );
for i = 1:numel(is)
  is(i) = str2double( col{i}(numel(beginning)+1:end) );
end

end