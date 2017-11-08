function add_depends(conf)

%   ADD_DEPENDS -- Add required dependencies.
%
%     IN:
%       - `conf` (struct) |OPTIONAL| -- Config file to use. Defaults to
%         saved config file.

if ( nargin < 1 ), conf = brains_analysis.config.load(); end

brains_analysis.util.assertions.assert__is_config( conf );
brains_analysis.util.assertions.assert__depends_present( conf );

depends = conf.DEPENDENCIES.repositories;
repo_path = conf.PATHS.repositories;

for i = 1:numel(depends)
  addpath( genpath(fullfile(repo_path, depends{i})) );
end

end