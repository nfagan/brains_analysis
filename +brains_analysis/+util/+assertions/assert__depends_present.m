function assert__depends_present(conf)

%   ASSERT__DEPENDS_PRESENT -- Ensure required dependencies are present.
%
%     IN:
%       - `conf` (struct) |OPTIONAL| -- Config file.

if ( nargin < 1 || isempty(conf) ), conf = brains_analysis.config.load(); end

brains_analysis.util.assertions.assert__is_config( conf );

repo_dir = conf.PATHS.repositories;
depends = conf.DEPENDENCIES.repositories;

for i = 1:numel(depends)
  assert( exist(fullfile(repo_dir, depends{i}), 'dir') == 7, ['The repository' ...
    , ' ''%s'', expected to be found in ''%s'', does not exist.'] ...
    , depends{i}, repo_dir );
end

end