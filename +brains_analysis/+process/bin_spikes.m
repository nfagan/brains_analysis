function [binned, time_vec] = bin_spikes(cont, events, min_t, max_t, window_size, step_size)

import shared_utils.assertions.*;

assert__isa( cont, 'Container' );
assert__isa( cont.data, 'cell' );
assert__isa( events, 'Container' );
assert__isa( events.data, 'double' );

dat = cont.data;

stps = (max_t - min_t) / step_size;
stps = stps + 1;

% binned = Container();

event_data = events.data;
binned_data = cell( numel(event_data) * numel(dat), stps );
binned_labs = SparseLabels();
bin_stp = 1;

cats_cont = cont.categories();
cats_events = events.categories();
cats_events_only = setdiff( cats_events, cats_cont );
for i = 1:numel(cats_events_only)
  cont = cont.require_fields( cats_events_only{i} );
end

for i = 1:numel(dat)
  fprintf( '\nProcessing %d of %d', i, numel(dat) );
  spike_vec = dat{i};
  one_spike = one( cont(i) );
  for k = 1:numel(event_data)
%     disp( k / numel(event_data) );
    event = event_data(k);

    one_event = events(k);
    new_spike = one_spike;      

    for h = 1:numel(cats_events_only)
%       new_spike( cats_events_only{h} ) = one_event( cats_events_only{h} );
      cat_ind_spk = strcmp( new_spike.labels.categories, cats_events_only{h} );
      cat_ind_evt = strcmp( one_event.labels.categories, cats_events_only{h} );
      new_spike.labels.labels(cat_ind_spk) = one_event.labels.labels(cat_ind_evt);
    end
    
    binned_ = cell( 1, stps );
    for j = 1:stps
      start = min_t + (step_size * (j-1)) - window_size/2;
      stop = min_t + (step_size * (j-1)) + window_size/2;
      start = start + event;
      stop = stop + event;
      ind = spike_vec >= start & spike_vec <= stop;
      spikes = spike_vec(ind);
      binned_{j} = struct( 'times', spikes );
    end
    
    binned_data(bin_stp, :) = binned_;
    binned_labs = binned_labs.append( new_spike.labels );
    
%     binned = binned.append( set_data(new_spike, binned_) );
    bin_stp = bin_stp + 1;
  end
end

time_vec = min_t:step_size:max_t;

binned = Container( binned_data, binned_labs );

end