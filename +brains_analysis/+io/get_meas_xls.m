function out = get_meas_xls(conf, sheet_name)

import shared_utils.io.dirnames;

if ( nargin < 1 || isempty(conf) ), conf = brains_analysis.config.load(); end
if ( nargin < 2 || isempty(sheet_name) ), sheet_name = 'Recording'; end

brains_analysis.util.assertions.assert__is_config( conf );

data_p = conf.PATHS.data.root;
free_p = fullfile( data_p, 'free_viewing', 'raw' );

xls_files = dirnames( free_p, '.xlsx', true );

assert( numel(xls_files) == 1, ['Expected 1 excel files to be present;' ...
  , ' instead there were %d.'], numel(xls_files) );

xls_file = xls_files{1};

[~, ~, out] = xlsread( xls_file, sheet_name );


end