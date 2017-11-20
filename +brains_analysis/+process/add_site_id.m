function [spike, lfp] = add_site_id(spike, lfp)

import shared_utils.assertions.*;

assert__isa( spike, 'Container' );
assert__isa( lfp, 'Container' );

assert( spike.contains('spike') && ~spike.contains('lfp') ...
  , 'Spike data cannot contain lfp data.' );
assert( lfp.contains('lfp') && ~lfp.contains('spike') ...
  , 'Lfp data cannot contain spike data.' );

cmbs_within = { 'channel', 'date', 'session' };

[lfp_site_indices, lfp_site_combs] = lfp.get_indices( cmbs_within );
[spk_site_indices, spk_site_combs] = spike.get_indices( cmbs_within );

chan_cat_ind = strcmp( cmbs_within, 'channel' );
assert( ~isempty(chan_cat_ind) );

lfp_msg = 'Wrong format for lfp channels. Must be FPXX or WBXX.';
spk_msg = 'Wrong format for spike channels. Must be SPKXX';

assert( all(cellfun(@(x) numel(x) == 5, spk_site_combs(:, chan_cat_ind))), spk_msg );
assert( all(cellfun(@(x) ~isempty(strfind(x, 'SPK')), spk_site_combs(:, chan_cat_ind))), spk_msg );
assert( all(cellfun(@(x) numel(x) == 4, lfp_site_combs(:, chan_cat_ind))), lfp_msg );
lfp_prefixes = cellfun( @(x) x(1:2), lfp_site_combs(:, chan_cat_ind), 'un', false );
assert( numel(unique(lfp_prefixes)) == 1, 'Data must be FP or WB, exclusively.' );

lfp_prefix = lfp_prefixes{1};
spk_prefix = 'SPK';

lfp_chan_numbers = cellfun( @(x) x(3:end), lfp_site_combs(:, chan_cat_ind), 'un', false );
spk_chan_numbers = cellfun( @(x) x(4:end), spk_site_combs(:, chan_cat_ind), 'un', false );

lfp_site_combs(:, chan_cat_ind) = lfp_chan_numbers;
spk_site_combs(:, chan_cat_ind) = spk_chan_numbers;

join_char = '/////||||';

lfp_site_combs = arr_join( lfp_site_combs, join_char );
spk_site_combs = arr_join( spk_site_combs, join_char );

shared = intersect( lfp_site_combs, spk_site_combs );
shared = arr_split( shared, join_char, numel(cmbs_within) );

lfp = lfp.require_fields( 'site_id' );
spike = spike.require_fields( 'site_id' );

stp = 1;

for i = 1:size(shared, 1)
  spk_current = shared(i, :);
  lfp_current = shared(i, :);
  
  spk_current{chan_cat_ind} = [ spk_prefix, spk_current{chan_cat_ind} ];
  lfp_current{chan_cat_ind} = [ lfp_prefix, lfp_current{chan_cat_ind} ];
  
  ind_spk = spike.where( spk_current );
  ind_lfp = lfp.where( lfp_current );
  
  assert( any(ind_spk) && any(ind_lfp) );
  
  spike( 'site_id', ind_spk ) = sprintf( 'site_id__%d', stp );
  lfp( 'site_id', ind_lfp ) = sprintf( 'site_id__%d', stp );
  
  stp = stp + 1;
end


end

function out = arr_split(c, s, cols)

out = cell( size(c, 1), cols );
for i = 1:numel(c), out(i, :) = strsplit( c{i}, s ); end

end

function out = arr_join(c, s)
out = cell( size(c, 1), 1 );
for i = 1:size(c, 1), out{i} = strjoin(c(i, :), s); end
end