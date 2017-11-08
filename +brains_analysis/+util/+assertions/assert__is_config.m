function assert__is_config(s)

%   ASSERT__IS_CONFIG -- Ensure an input is a valid config variable.
%
%     IN
%       - `s` (struct)

msg = ['Expected input to be a config file: to be a struct with a' ...
    , ' `CONFIG_ID__` field.'];

assert( isa(s, 'struct'), 'Config file must be a struct; was ''%s''.', class(s) );
assert( isfield(s, 'CONFIG_ID__'), msg );

end