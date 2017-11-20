function aligned = align_plex_by_pair_id(neural_data, starts)

import shared_utils.assertions.*;

assert__isa( neural_data, 'Container' );
assert__isa( starts, 'Container' );

assert__isa( neural_data.data, 'cell' );
assert__isa( starts.data, 'double' );

assert__is_vector( neural_data.data );
assert__is_vector( starts.data );

[I, session_combs] = neural_data.get_indices( {'date', 'session', 'channel', 'unit_n'} );

aligned = Container();

for i = 1:numel(I)
  subset = neural_data( I{i} );
  assert( shape(subset, 1) == 1, 'Too many elements!' );
  type = char( subset('channel_type') );
  
  matching_start = starts.only( subset.flat_uniques({'date','session'}) );
  assert( ~isempty(matching_start), 'No starts matched!' );
  
  switch ( type )
    case 'lfp'
      lfp = process_lfp( subset, matching_start );
      aligned = aligned.append( lfp );
    case 'spike'
      spikes = process_spikes( subset, matching_start );
      aligned = aligned.append( spikes );
    otherwise
      error( 'Unrecognized channel type ''%s''', type );
  end
  
end

end

function lfp = process_lfp( subset, matching_start )

import shared_utils.assertions.*;

EPSILON = 1e-3; % 1ms tolerance

pair_ids = sort_pair_ids( matching_start('pair_id') );
data = subset.data{1};
assert__isa( data, 'struct' );
assert__are_fields( data, {'Values', 'FragTs', 'ADFreq'} );
assert( numel(data.FragTs) == 1, 'More than one fragment for %s.' ...
  , strjoin(subset.flat_uniques({'date', 'session'}), ', ') );

time_vec = (0:numel(data.Values)-1) * (1/data.ADFreq);
time_vec = time_vec + data.FragTs;

last_start_time = -Inf;

lfp = Container();

for i = 1:numel(pair_ids)
  ind_start = matching_start.where( pair_ids{i} );
  
  assert( sum(ind_start) == 1, 'Too many data points associated with the given start pair id!' );
  start_time = matching_start.data(ind_start) / 1e3;

  if ( i < numel(pair_ids) )
    ind_end = matching_start.where( pair_ids{i+1} );
    assert( sum(ind_end) == 1, 'Too many data points associated with the given end pair id!' );
    end_time = matching_start.data(ind_end) / 1e3;
  else
    end_time = time_vec(end);
  end
  
  assert( start_time > last_start_time && end_time > start_time ...
    , 'Start times must be increasing!' );
  
  [~, closest_start] = min( abs(time_vec - start_time) );
  [~, closest_end] = min( abs(time_vec - end_time) );
  
  error_amt_start = abs( time_vec(closest_start) - start_time );
  assert( error_amt_start < EPSILON, ['Difference between' ...
    , ' nearest start time and actual start was %0.3f (s), exceeding the given' ...
    , ' threshold of %0.3f (s), for %s.'], error_amt_start, EPSILON ...
    , strjoin(subset.flat_uniques({'date', 'session'}), ', ') );
  
  error_amt_end = abs( time_vec(closest_end) - end_time);
  assert( error_amt_end < EPSILON, ['Difference between' ...
    , ' nearest end time and actual end was %0.3f (s), exceeding the given' ...
    , ' threshold of %0.3f (s), for %s.'], error_amt_end, EPSILON ...
    , strjoin(subset.flat_uniques({'date', 'session'}), ', ') );
  
  n_time_points = (closest_end - closest_start);
  aligned_time_vec = (0:n_time_points-1) * (1/data.ADFreq);
  
  new_data = data;
  new_data.Values = data.Values(closest_start:closest_end-1);
  new_data.time = aligned_time_vec;
  new_lfp = set_data( subset, {new_data} );
  new_lfp = new_lfp.require_fields( 'pair_id' );
  new_lfp( 'pair_id' ) = pair_ids{i};
  
  lfp = lfp.append( new_lfp );
  
  last_start_time = start_time;
end

end

function new_spikes = process_spikes( subset, matching_start )

pair_ids = sort_pair_ids( matching_start('pair_id') );
data = subset.data{1};

new_spikes = Container();

last_start_time = -Inf;

for i = 1:numel(pair_ids)
  ind = matching_start.where( pair_ids{i} );
  assert( sum(ind) == 1, 'Too many data points associated with the given pair id!' );
  start_time = matching_start.data(ind) / 1e3;
  
  assert( start_time > last_start_time, 'Start times must be increasing!' );
  
  adjusted_data = data - start_time;
  
  new_spike = set_data(subset, {adjusted_data});
  new_spike = new_spike.require_fields( 'pair_id' );
  new_spike( 'pair_id' ) = pair_ids{i};
  new_spikes = new_spikes.append( new_spike );
  
  last_start_time = start_time;
end

end

function pair_ids = sort_pair_ids( pair_ids )

cellfun( @(x) assert(~isempty(strfind(x, 'pair_id__')) ...
  , 'Pair ids are formatted incorrectly.'), pair_ids );

id_ns = zeros( size(pair_ids) );

for i = 1:numel(pair_ids)
  res = str2double( pair_ids{i}(numel('pair_id__')+1:end) );
  assert( ~isnan(res), 'Wrong format.' );
  id_ns(i) = res;
end

[~, I] = sort( id_ns );
pair_ids = pair_ids(I);

end