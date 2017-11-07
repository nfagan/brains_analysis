function s = fill_missing_fields(s, subfield)

%   FILL_MISSING_FIELDS -- Fill missing fields of a struct with NaN.
%
%     IN:
%       - `s` (struct)
%       - `sub_field` (char)
%     OUT:
%       - `s` (struct)

if ( nargin < 2 )
  subfield = 'events';
end

all_fields = arrayfun( @(x) fieldnames(x.(subfield)), s, 'un', false );
ns = cellfun( @numel, all_fields );
N = max( ns );
all_fields = all_fields{ N };

for i = 1:numel(s)
  for j = 1:numel(all_fields)
    if ( ~isfield(s(i).(subfield), all_fields{j}) )
      s(i).(subfield).(all_fields{j}) = NaN;
    end
  end
end

end