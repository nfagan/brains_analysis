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
      error( 'Not yet implemented.' );
    case 'spike'
      spikes = process_spikes( subset, matching_start );
      aligned = aligned.append( spikes );
    otherwise
      error( 'Unrecognized channel type ''%s''', type );
  end
  
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