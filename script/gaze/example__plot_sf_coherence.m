conf = brains_analysis.config.load();
datap = fullfile( conf.PATHS.data.root, 'free_viewing', 'processed', 'plex', 'sf_coherence' );

io = brains_analysis.io.get_fv_h5( conf, fullfile('plex', 'gaze_aligned_lfp.h5') );
iteration = 'A';
meta = io.read( io.fullfile('Meta', iteration) );

mats = shared_utils.io.dirnames( datap, '.mat' );

acc_bla = cellfun( @(x) ~isempty(strfind(x, 'BLA_ACC')), mats );
acc_bla = mats( acc_bla );
conts = cell( 1, numel(acc_bla) );
for i = 1:numel(acc_bla)
  fprintf( '\n %d of %d', i, numel(acc_bla) );
  cont = shared_utils.io.fload( fullfile(datap, acc_bla{i}) );
  cont = cont.each1d( {'gaze_type', 'roi', 'site_id'}, @rowops.nanmean );
  conts{i} = cont;
end

cont = Container.concat( conts );
cont = SignalContainer( cont.data, cont.labels );
cont.data = cont.data(:, 1:65, :);
cont.frequencies = meta.frequencies;
cont.start = meta.start;
cont.stop = meta.stop;
cont.step_size = meta.step_size;
cont.window_size = meta.window_size;

%%

meaned = cont.each1d( {'gaze_type', 'roi'}, @rowops.nanmean );

%%

plt = meaned;
figure(1); clf();

plt.spectrogram( {'gaze_type', 'roi'}, 'shape', [2, 2] );


