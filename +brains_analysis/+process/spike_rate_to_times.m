function dat = spike_rate_to_times(data, bin_size)

spk_counts = data .* bin_size;

dat = cell( 1, size(data, 2) );

for i = 1:size(spk_counts, 2)
  window = spk_counts(:, i);
  s = struct( 'times', [] );
  for j = 1:numel(window)
    n_spks = window(j);
    mat = zeros( n_spks, 1 );
    for k = 1:n_spks
      mat(k) = (k-1) * bin_size/n_spks;
    end
    s(j) = struct( 'times', mat );
  end
  dat{i} = s;
end

end