function rois = get_rois(conf)

%   GET_ROIS -- Get the rois struct from the rois.json file.
%
%     IN:
%       - `conf` (struct) |OPTIONAL|
%     OUT:
%       - `rois` (struct)

if ( nargin < 1 || isempty(conf) ), conf = brains_analysis.config.load(); end

brains_analysis.util.assertions.assert__is_config( conf );

roi_path = fullfile( conf.PATHS.data.root, conf.PATHS.data.free_viewing, 'raw', 'rois.json' );
rois = brains_analysis.util.io.try_json_decode( roi_path );

end