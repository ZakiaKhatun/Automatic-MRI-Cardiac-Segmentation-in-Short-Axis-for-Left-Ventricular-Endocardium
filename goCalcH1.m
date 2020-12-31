function [h1_mag, h1_phi] = goCalcH1(vol)
% perform 1-cycle mini Fourier transform (first harmonic)
% can also use built-in FFT function, but this seemed more straightforward
[~, ~, ~, sz_t] = size(vol);
theta = shiftdim(2*pi*((1:sz_t)'-1) / sz_t, -3);  % sinusoid of frequency 1, along 3rd dimension
h1_cos = squeeze(sum(bsxfun(@times, vol,  cos(theta)), 4));
h1_sin = squeeze(sum(bsxfun(@times, vol, -sin(theta)), 4));
h1_mag = sqrt(h1_cos.^2 + h1_sin.^2);  % magnitude
h1_phi = atan2(-h1_cos, h1_sin);  % phase