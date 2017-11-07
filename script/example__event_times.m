%%  define data files, add pl2 sdk to path

repo_path = '/Volumes/My Passport/NICK/Chang Lab 2016/repositories';
addpath( fullfile(repo_path, 'brains_analysis') );
addpath( fullfile(repo_path, 'shared_utils') );

addpath( genpath('/Volumes/My Passport/NICK/Chang Lab 2016/LFP/Plexon Offline SDKs') );

% rule cue onset

% mat_file = '/Volumes/My Passport/NICK/Chang Lab 2016/brains/debug/rule_cue_correct_trial_alignment.mat';
% pl2_file = '/Volumes/My Passport/NICK/Chang Lab 2016/brains/debug/rule_cue_correct_trial_alignment.pl2';

% fixation delay (triangle onset)

mat_file = '/Volumes/My Passport/NICK/Chang Lab 2016/brains/debug/fix_delay_stim_onset.mat';
pl2_file = '/Volumes/My Passport/NICK/Chang Lab 2016/brains/debug/fix_stim_on.pl2';

% mat_file = '/Volumes/My Passport/NICK/Chang Lab 2016/brains/debug/test_sync1.mat';
% pl2_file = '/Volumes/My Passport/NICK/Chang Lab 2016/brains/debug/debug__sync1.pl2';

% mat_file = '/Volumes/My Passport/NICK/Chang Lab 2016/brains/debug/rule_cue_sync.mat';
% pl2_file = '/Volumes/My Passport/NICK/Chang Lab 2016/brains/debug/rule_cue.pl2';

% mat_file = '/Volumes/Setup3/brains_data/debug/fixation_delay_sync.mat';
% pl2_file = '/Volumes/Setup3/brains_data/debug/fixation_delay_triangle.pl2';

data = load( mat_file ); data = data.( char(fieldnames(data)) );

data.DATA = brains_analysis.process.fill_missing_fields( data.DATA );

%%  plex events

import brains_analysis.process.*;

% all_channels = { 'AI02', 'AI03', 'AI04' };
all_channels = { 'AI02', 'AI05' };
trial_start_channel = 'AI02';

plx_evts = get_plex_events( pl2_file, all_channels, trial_start_channel );

%%  mat events

evts = arrayfun( @(x) x.events, data.DATA, 'un', false );
mat_starts = cellfun( @(x) x.trial_start, evts );
% mat_cue_on = cellfun( @(x) x.rule_cue_onset, evts );
mat_cue_on = cellfun( @(x) x.fixation_delay_stim_onset, evts );
% mat_cue_on = cellfun( @(x) x.fixation_delay, evts );

mat_evts = [ mat_starts(:), mat_cue_on(:) ];
mat_evts = mat_evts .* 1e3; % to ms.

plx_evts = [ plx_evts(:, 1), plx_evts(:, 2) ];

%%  compare

n_mats = size( mat_evts, 1 );
n_plx = size( plx_evts, 1 );

if ( n_mats > n_plx )
  mat_evts = mat_evts(1:n_plx, :);
elseif ( n_mats < n_plx )
  plx_evts = plx_evts(1:n_mats, :);
end

plx_offset = diff( plx_evts, 1, 2 );
mat_offset = diff( mat_evts, 1, 2 );

diffs = abs( mat_offset - plx_offset );

mean_diff = nanmean( diffs );
dev_diff = nanstd( diffs );
max_diff = max( diffs );

fprintf( '\nN samples:        %d', size(diffs, 1) - sum(any(isnan(diffs), 2)) );
fprintf( '\nMean discrepency: %0.2f (ms)', mean_diff );
fprintf( '\nStd discrepency:  %0.2f (ms)', dev_diff );
fprintf( '\nMax discrepency:  %0.2f (ms)', max_diff );
fprintf( '\n\n' );

%%  get spikes

spikes = PL2Ts( pl2_file, 'SPK09', 1 );
target_events = plx_evts(:, 2);
target_events = target_events( ~isnan(target_events) );
min_t = -1.5e3;
max_t = 1.5e3;
bin_width = 200;

spikes = spikes * 1e3;

[psth, binT] = get_basic_psth( spikes, target_events, min_t, max_t, bin_width );
psth = psth * 1e3;

figure(1); clf();
plot( binT, psth );

xlabel( 'Time (ms) from fixation triangle onset' );
ylabel( 'sps' );

saveas( gcf, fullfile('/Volumes/My Passport/NICK/Chang Lab 2016/brains/debug', 'fixation_delay'), 'png' );


