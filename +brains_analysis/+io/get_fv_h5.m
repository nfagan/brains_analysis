function io = get_fv_h5( conf, subpath )

%   GET_FV_H5 -- Get an interface to a free_viewing .h5 file.
%
%     IN:
%       - `conf` (struct) |OPTIONAL| -- config file.
%       - `subpath` (char) -- The .h5 file name / subpath.
%     OUT:
%       - `io` (h5_api)

import brains_analysis.util.assertions.assert__is_config;
import shared_utils.assertions.*;

if ( nargin < 1 || isempty(conf) ), conf = brains_analysis.config.load(); end

assert__isa( subpath, 'char' );
assert__is_config( conf );

data_p = conf.PATHS.data.root;

h5_p = fullfile( data_p, 'free_viewing', 'processed', subpath );

io = h5_api( h5_p );

end