function validate__session_folder( pathstr )

%   VALIDATE__SESSION_FOLDER -- Ensure a session folder is valid.
%
%     IN:
%       - `pathstr` (char)

import shared_utils.assertions.*;
import shared_utils.io.dirnames;

assert__is_dir( pathstr, 'session subfolder' );
assert__is_dir( fullfile(pathstr, 'mat'), 'mat subfolder' );
assert__is_dir( fullfile(pathstr, 'edf'), 'edf subfolder' );
assert__is_dir( fullfile(pathstr, 'plex'), 'plex subfolder' );
assert__is_dir( fullfile(pathstr, 'edf', 'm1'), 'm1 sub-subfolder' );
assert__is_dir( fullfile(pathstr, 'edf', 'm2'), 'm2 sub-subfolder' );

assert__file_exists( fullfile(pathstr, 'mat', 'distances.json') );
assert__file_exists( fullfile(pathstr, 'mat', 'meta.json') );

m1_edfs = dirnames( fullfile(pathstr, 'edf', 'm1'), '.edf' );
m2_edfs = dirnames( fullfile(pathstr, 'edf', 'm2'), '.edf' );

assert( numel(m1_edfs) == numel(m2_edfs) && numel(m1_edfs) > 0 ...
  , ['Expected the number of .edf files for m1 and m2 to match, and be' ...
  , ' greater than 0.'] );

pl2s = dirnames( fullfile(pathstr, 'plex'), '.pl2' );
assert( numel(pl2s) == 0 || numel(pl2s) == 1, ['Expected one .pl2 file in ''%s''; instead' ...
  , ' there were %d.'], pathstr, numel(pl2s) );

end