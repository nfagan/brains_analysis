function eg__position_plot( monk1, monk2, key )

import shared_utils.assertions.*;
assert__isa( monk1, 'Container' );
assert__isa( monk2, 'Container' );

assert( numel(key) == shape(monk1, 2), ['Number of key elements must' ...
  , ' match number of columns in data.'] );
assert( shape(monk1, 2) == shape(monk2, 2), 'Shapes must match.' );

assert( numel(monk1('monkey')) == 1 && numel(monk2('monkey')) == 1 ...
  , 'Too many monkeys in the given data subset.' );

bounds_ind = strcmp( key, 'in_bounds' );
assert( any(bounds_ind), 'Key is missing an ''in_bounds'' id.' );

m1_lab = char( monk1('monkey') );
m2_lab = char( monk2('monkey') );

figure(1); clf();
ax(1) = subplot( 1, 2, 1 );
plot( monk1.data(:, 1), monk1.data(:, 2), 'k*', 'markersize', .1 );
inb1 = monk1.data(:, bounds_ind) == 1;
hold on;
plot( monk1.data(inb1, 1), monk1.data(inb1, 2), 'r*', 'markersize', .1 );

title( sprintf('%s looks to %s', m1_lab, m2_lab) );

ax(2) = subplot( 1, 2, 2 );
plot( monk2.data(:, 1), monk2.data(:, 2), 'k*', 'markersize', .1 );
inb2 = monk2.data(:, bounds_ind) == 1;
hold on;
plot( monk2.data(inb2, 1), monk2.data(inb2, 2), 'r*', 'markersize', .1 );

title( sprintf('%s looks to %s', m2_lab, m1_lab) );

set( ax, 'xlim', [-150, 150] );
set( ax, 'ylim', [-100, 100] );

end