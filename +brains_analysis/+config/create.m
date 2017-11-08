function conf = create()

%   CREATE -- Create the config file.
%
%     OUT:
%       - `conf` (struct)

conf = struct();

conf.CONFIG_ID__ = true;

PATHS.data = struct();
PATHS.repositories = '/Volumes/My Passport/NICK/Chang Lab 2016/repositories';
PATHS.plexon = 'plexon';
PATHS.data.root = '/Volumes/My Passport/NICK/Chang Lab 2016/brains';
PATHS.data.free_viewing = 'free_viewing';

DEPENDENCIES = struct();
DEPENDENCIES.repositories = { 'shared_utils', 'plexon', 'eyelink', 'global', 'h5_api', 'jsonlab-1.5' };

conf.PATHS = PATHS;
conf.DEPENDENCIES = DEPENDENCIES;

brains_analysis.config.save( conf );

end