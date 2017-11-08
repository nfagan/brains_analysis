function out = meas_xls2mat( meas )

import shared_utils.assertions.*;

assert__isa( meas, 'cell', 'the excel measurements' );
assert( strcmp(meas{1, 1}, 'Session'), 'The first row label must be ''Sesssion''.' );
assert( strcmp(meas{2, 1}, 'Channels'), 'The second row label must be ''Channels''.' );
assert( strcmp(meas{2, 2}, 'Area'), 'The second row, second column label must be ''Area''.' );

session_ids = meas(1, :);
assert( sum(cellfun(@(x) ~isnumeric(x), meas(2, :))) == 2 ...
  , 'Only two non-string column labels can be present.' );

area_ind = strcmp( meas(2, :), 'Area' );
channel_ind = strcmp( meas(2, :), 'Channels' );

non_sessions = area_ind | channel_ind;
session_ids(non_sessions) = [];
session_ids = cell2mat( session_ids );
date_ids = cell2mat( meas(2, ~non_sessions) );

assert( numel(date_ids) == numel(session_ids), 'Number of dates and sessions must match' );

area_col = meas(3:end, area_ind);
is_area = cellfun( @(x) strcmpi(x, 'bla') | strcmpi(x, 'acc'), area_col );
last_area = find( is_area, 1, 'last' );
assert( ~isempty(last_area) );
last_row = last_area + 2;

unit_numbers = [];
channel_labels = {};
region_labels = {};
date_labels = {};
session_labels = {};
spike_v_lfp_labels = {};

for i = 1:numel(session_ids)
  sesh_ind = cellfun( @(x) isequal(x, session_ids(i)), meas(1, :) );
  date_ind = cellfun( @(x) isequal(x, date_ids(i)), meas(2, :) );
  current = sesh_ind & date_ind;
  assert( sum(current) == 1, 'More than one session matched!' );
  col = meas( :, current );
  
  date_lab = num2str( meas{2, current} );
  sesh_lab = sprintf( 'session__%d', meas{1, current} );
  
  for j = 3:last_row
    
    channel = meas{j, channel_ind};
    region = meas{j, area_ind};
    spike_lfp_key = col{j};
    
    assert( ~any(isnan(spike_lfp_key)), 'Key was NaN' );
    
    if ( isnumeric(spike_lfp_key) && spike_lfp_key == -1 ), continue; end
    
    if ( channel < 10 )
      chan_lab = sprintf( '0%d', channel );
    else
      chan_lab = sprintf( '%d', channel );
    end
    
    %   lfp
    channel_labels{end+1} = sprintf( 'FP%s', chan_lab );
    unit_numbers(end+1) = NaN;
    region_labels{end+1} = region;
    date_labels{end+1} = date_lab;
    session_labels{end+1} = sesh_lab;
    spike_v_lfp_labels{end+1} = 'lfp';
    
    %   spikes
    
    if ( isnumeric(spike_lfp_key) )
      units_to_use = 1:spike_lfp_key;
    else
      key = strsplit( spike_lfp_key, ',' );
      key( cellfun(@isempty, key) ) = [];
      assert( ~isempty(key), 'No elements matched!' );
      nums = cellfun( @str2double, key, 'un', false );
      assert( ~any(cellfun(@isnan, nums)), 'Wrong format.' );
      units_to_use = cell2mat( nums );
    end
    
    for k = 1:numel(units_to_use)
      channel_labels{end+1} = sprintf( 'SPK%s', chan_lab );
      unit_numbers(end+1) = units_to_use(k);
      region_labels{end+1} = region;
      date_labels{end+1} = date_lab;
      session_labels{end+1} = sesh_lab;
      spike_v_lfp_labels{end+1} = 'spike';
    end
    
  end
end

out = struct();
out.unit = unit_numbers;
out.channel = channel_labels;
out.channel_type = spike_v_lfp_labels;
out.region = region_labels;
out.date = date_labels;
out.session = session_labels;

end