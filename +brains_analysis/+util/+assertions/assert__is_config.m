function assert__is_config(s)

%   ASSERT__IS_CONFIG -- Ensure an input is a valid config variable.
%
%     IN
%       - `s` (struct)

try
  shared_utils.assertions.assert__isa( s, 'struct' );
  shared_utils.assertions.assert__are_fields( s, 'CONFIG_ID__' );
catch err
  error( ['Expected input to be a config file: to be a struct with a' ...
    , ' `CONFIG_ID__` field.'] );
end

end