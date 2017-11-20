function all_signals = get_lfp_mat( plex, id_times, events, start_stop, w_size, fs )

%   GET_SIGNALS -- Given a vector of event times, get a signal vector of
%     desired length aligned to those events.
%
%     IN:
%       - `plex` (double) -- Complete signal vector from which to draw 
%         samples.
%       - `id_times` (double) -- Complete id_times vector identifying the
%         time of each point in `plex`.
%       - `events` (double) -- Vector of event times. Event-times that are
%         0 will not be searched for; accordingly, the corresponding rows
%         in `all_signals` will be all zeros. All non-zero event-times must
%         be in bounds of `id_times`.
%       - `start_stop` (double) -- Where to start and stop relative to t=0
%         as the actual event time. E.g., `start_stop` = [-1000 1000]
%         starts -1000 ms relative to each events(i), and stops 1000ms post
%         each events(i).
%       - `w_size` (double) |SCALAR| -- Window-size. Used to shift the
%         start of the signal vector such that the center of each window is
%         the time-point associated with that window.
%       - `fs` (double) |SCALAR| -- Sampling rate of the signals in `plex`.
%     OUT:
%       - `all_signals` (double) -- Matrix of signals in which each
%         row(i, :) corresponds to each `events`(i). Rows of `all_signals`
%         will be entirely zero where events == 0.

assert( size(events, 2) == 1, ['Expected there to be only 1 column of events' ...
  , ' data, but there were %d'], size(events, 2) );
assert( numel(start_stop) == 2, 'Specify `start_stop` as a two-element vector' );
assert( start_stop(2) > start_stop(1), ['`start_stop`(2) must be greater than' ...
  , ' `start_stop`(1)'] );

is_zero = events(:,1) == 0;
non_zero_events = events( ~is_zero, : );

amount_ms = (start_stop(2) - start_stop(1)) * (fs/1e3);
start = start_stop(1)/1e3;
w_size = w_size/1e3;

non_zero_events = non_zero_events + start;
non_zero_events = non_zero_events - w_size/2; % properly center each window.

signals = nan( size(non_zero_events,1), amount_ms );
all_signals = nan( size(events, 1), amount_ms );

for i = 1:size(non_zero_events, 1)
  current_time = non_zero_events(i);
  [~, index] = histc( current_time, id_times );
  out_of_bounds_msg = ['The id_times do not properly correspond to the' ...
    , ' inputted events'];
  is_in_bounds = index ~= 0 && (index+amount_ms-1) <= numel( plex );
  if ( ~is_in_bounds )
    fprintf( ['\n\n WARNING: Event beginning at %0.3f was out of bounds' ...
      , ' of the given id times, which begin at %0.3f and end at %0.3f'] ...
      , current_time, min(id_times), max(id_times) );
    continue;
  end
%   assert( is_in_bounds, out_of_bounds_msg );
  check = abs( current_time - id_times(index) ) < abs( current_time - id_times(index+1) );
  if ( ~check ), index = index + 1; end;
  signals(i, :) = plex( index:index+amount_ms-1 );
end

all_signals( ~is_zero, : ) = signals;

end