function plex_events = get_plex_events(file, channels, start_channel, n_trials)

%   GET_PLEX_EVENTS -- Read in pulsed-event times from a .pl2 file.
%
%     evts = ... get_plex_events( 'eg.pl2', {'AI01', 'AI02'}, 'AI01' );
%
%     loads event times in the .pl2 file 'eg.pl2' in channels 'AI01' and
%     'AI02', with 'AI01' specifying the trial-start times channel. `evts`
%     is an MxN array of event-times in M-trials by N-channels, such that
%     each column (i) of `evts` corresponds to the inputted `channels`(i).
%     Event-times in each trial are either a number or NaN if the event is
%     not present.
%
%     evts = ... get_plex_events( ..., 1000 ) tells the function to expect
%     1000 trials to be present, which can help speed up execution.
%
%     An error is thrown if a) the .pl2 file does not exist, b) the given 
%     channels are not present in the .pl2 file, or c) the trial start 
%     channel is not also specified in the channels array.
%
%     This function works by scanning each channel's input vector for
%     points that cross a ~4.9v threshold.
%
%     IN:
%       - `file` (char)
%       - `channels` (cell array of strings, char)
%       - `start_channel` (char)
%       - `n_trials` (double) |OPTIONAL|
%     OUT:
%       - `plex_events` (double)

import shared_utils.assertions.*;

if ( ~iscell(channels) ), channels = { channels }; end

if ( nargin < 4 )
  n_trials = 1e3; 
else
  assert__is_scalar( n_trials, 'the number of trials' );
end

thresh = 4.9e3; % 5v pulse

assert__file_exists( file, '.pl2 file' );
assert__is_cellstr( channels, 'the channels' );
assert__isa( start_channel, 'char', 'the trial-start channel' );
assert( numel(unique(channels)) == numel(channels), 'Do not specify duplicate channels.' );

start_col = strcmp( channels, start_channel );
assert( any(start_col), 'The start channel must exist in the channels array.' );

pl2 = PL2GetFileIndex( file );

ai_chan_index = cellfun( @(x) any(cellfun(@(y) strcmp(y, x.Name), channels)) ...
  , pl2.AnalogChannels );

assert( sum(ai_chan_index) == numel(channels), ['Some of the given' ...
  , ' channels do not exist in the .pl2 file.'] );

fs = cellfun( @(x) x.SamplesPerSecond, pl2.AnalogChannels(ai_chan_index) );
%   warn if we're not using 1khz sampling rate for the analog input
%   channels.
if ( ~all(fs == 1e3) )
  warning( ['The sampling rate(s) of the given channel(s) are not all' ...
    , ' 1khz. You''ll have to transform the output of this function' ...
    , ' to be in ms.'] );
end

%   get event times for each channel
ads = cellfun( @(x) PL2Ad(file, x), channels, 'un', false );
ads = cell2mat( cellfun(@(x) x.Values, ads, 'un', false) );

event_times = cell( 1, numel(channels) );
event_time = nan( n_trials, 1 );

for i = 1:numel(channels)  
  ad = ads(:, i);
  above_thresh = ad > thresh;
  inds = find( above_thresh );
  
  event_stp = 1;
  event_time(:) = NaN;
  
  while ( ~isempty(inds) )
    %   first event time, in ms
    first = inds(1);
    event_time(event_stp) = first;
    %   get the subset of the above_thresh index that begins at the
    %   event-time and ends at the end of the vector
    ind_subset = above_thresh( first:end );
    %   the end of the pulse is the first ind_subset value that isn't 1
    %   (true)
    ad_end = find( ~ind_subset, 1, 'first' );
    %   delete the subset of true values (ending at ad_end-1) that have
    %   already been accounted for
    inds(1:ad_end-1) = [];
    event_stp = event_stp + 1;
  end
  
  event_times{i} = event_time(1:event_stp-1);
end

%   if we just have trial starts, return now
if ( numel(event_times) == 1 ), plex_events = event_times{1}; return; end

trial_starts = event_times{ start_col };
other_evts = event_times( ~start_col );
other_chans = channels( ~start_col );

plex_events = nan( numel(trial_starts)-1, numel(channels) );

for i = 1:numel(trial_starts)-1  
  current = trial_starts(i);
  next = trial_starts(i+1);
  
  plex_events(i, start_col) = current;
  
  for j = 1:numel(other_evts)    
    other_col = strcmp( channels, other_chans{j} );
    
    other_times = other_evts{j};
        
    ind = other_times > current & other_times < next;
    %   event must either occur once or not at all
    assert( sum(ind) <= 1, ['The event in channel %s appeared to occur' ...
      , ' more than once this trial.'], other_chans{j} );
    
    if ( ~any(ind) ), continue; end
    
    plex_events(i, other_col) = other_times( ind );
  end
end

end