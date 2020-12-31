% parse binary objects for 3d/4d volume
function [info_vol, px2d_vol] = goParseBinaryObjs(cc_vol)
sz = cc_vol.ImageSize;
assert(length(sz) == 3  ||  length(sz) == 4);
if length(sz) == 3;
    sz_y = sz(1);  sz_x = sz(2);  sz_t = 1;      sz_z = sz(3);
else
    sz_y = sz(1);  sz_x = sz(2);  sz_z = sz(3);  sz_t = sz(4);
end

[xx, yy] = meshgrid(1:sz_x, 1:sz_y);
px_areas = cellfun(@numel, cc_vol.PixelIdxList);  % get areas
px_sample = cellfun(@(x) x(1), cc_vol.PixelIdxList);  % just get 1st pixel of every object ...
[~, ~, n_z, n_t] = ind2sub([sz_y, sz_x, sz_z, sz_t], px_sample);  % ... to determine phase and slice
offsets = sz_y*sz_x*sz_z * (n_t - 1) + sz_y*sz_x * (n_z - 1);
info_vol(1:cc_vol.NumObjects,1) = struct('slice', 0, 'phase', 0, 'area', 0, 'Cxy', [0 0]);
px2d_vol = cell(cc_vol.NumObjects, 1);
for n = 1:cc_vol.NumObjects
    info_vol(n).slice = n_z(n);
    info_vol(n).phase = n_t(n);
    info_vol(n).area = px_areas(n);
    px2d = cc_vol.PixelIdxList{n} - offsets(n);
    info_vol(n).Cxy = [ mean(xx(px2d))  mean(yy(px2d)) ];
    px2d_vol{n} = px2d;
end