function [bw4d, thres_hilo, thres_h1] = goThresholdVol(vol4d, vol3d_h1mag, bw3d_valid)
% first get the binary volume of "strong moving objects" from H1 magnitude
data = vol3d_h1mag(bw3d_valid);
data_max = prctile(data, 99);
data(data > data_max) = data_max;  % threshold at 99%
level = graythresh(data / data_max);
thres_h1 = level * data_max;
bw3d_h1mag = (vol3d_h1mag >= thres_h1)  &  bw3d_valid;

% now get the intensity threshold by iteratively scanning the maximum
% intensity projection volume against the binary "strong moving objects"
% volume until we get a match
vol3d_max = squeeze(max(vol4d, [], 4));
low_high = prctile(vol3d_max(bw3d_valid), [1 99]);
levels = linspace(low_high(1), low_high(2), 256);  % keep to 256 levels for speed
data = vol3d_max(bw3d_h1mag);
data_cnt = numel(data);
for thres_hilo = levels(:)'  % iterate until at most 95% coverage
    if (sum(data >= thres_hilo) / data_cnt) <= 0.95;  break;  end
end
sz_t = size(vol4d, 4);
bw4d_valid = repmat(permute(bw3d_valid, [1 2 3 4]), [1 1 1 sz_t]);
bw4d = (vol4d >= thres_hilo)  &  bw4d_valid;