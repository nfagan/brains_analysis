function starts = find_logical_starts(vec, min_length)

%   FIND_LOGICAL_STARTS -- Return indices of the beginning of sequences of
%     true values.
%
%     starts = ... find_logical_starts( [true, true, false, true] ) returns
%     [1, 4].
%
%     starts = ... find_logical_starts( [true, true, false, true], 2 ) only
%     includes starts of sequences of at least 2 true values, and returns
%     [1].
%
%     IN:
%       - `vec` (logical)
%       - `min_length` (double) |OPTIONAL| -- Minimum sequence length.
%       	Defaults to 1.
%     OUT:
%       - `starts` (double)

import shared_utils.assertions.*;

if ( nargin < 2 ), min_length = 1; end

assert__is_vector( vec );
assert__isa( vec, 'logical' );
assert__is_scalar( min_length );
assert__isa( min_length, 'double' );

starts = nan( size(vec) );
stp = 1;
seq_length = 0;

was_started = false;

for i = 1:numel(vec)
  
  if ( vec(i) && ~was_started )
    starts(stp) = i;
    stp = stp + 1;
    seq_length = 1;
    was_started = true;
  elseif ( vec(i) && was_started )
    seq_length = seq_length + 1;
  elseif ( ~vec(i) && was_started )
    was_started = false;
    if ( seq_length < min_length )
      starts(stp-1) = NaN;
      stp = stp - 1;
    end
  end
end

if ( seq_length < min_length && vec(end) )
  starts(stp-1) = NaN;
  stp = stp - 1;
end

starts(stp:end) = [];

end