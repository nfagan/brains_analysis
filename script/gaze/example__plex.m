import brains_analysis.process.get_plex_events;

conf = brains_analysis.config.load();
data_p = conf.PATHS.data;

plx_dir = fullfile( data_p.root, data_p.free_viewing, 'raw', '110217', 'plex' );
edf_dir = fullfile( data_p.root, data_p.free_viewing, 'raw', '110217', 'edf' );

pl2s = shared_utils.io.dirnames( plx_dir, '.pl2', true );
edfs = shared_utils.io.dirnames( fullfile(edf_dir, 'm1'), '.edf', true );

pl2_name = pl2s{1};
pl2 = PL2GetFileIndex( pl2_name );

chan = 'SPK09';

ts = PL2Ts( pl2_name, chan, 0 );

all_channels = { 'AI02' };
trial_start_channel = 'AI02';

plx_evts = get_plex_events( pl2_name, all_channels, trial_start_channel );

%%


