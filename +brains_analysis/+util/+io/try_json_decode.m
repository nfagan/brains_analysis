function out = try_json_decode(filepath)

%   TRY_JSON_DECODE -- Attempt to decode a .json file.
%
%     IN:
%       - `filepath` (char)
%     OUT:
%       - `out` (/any/)

import shared_utils.assertions.*;

assert__file_exists( filepath );

try
  if ( verLessThan('matlab', 'R2017a') )
    out = loadjson( filepath );
  else
    out = jsondecode( fileread(filepath) );
  end
catch err
  msg = sprintf( ['The following error ocurred when attempting to parse' ...
    , ' the .json file ''%s''.'], filepath );
  fprintf( '\n\n%s\n\n', msg );
  throw( err );
end

end