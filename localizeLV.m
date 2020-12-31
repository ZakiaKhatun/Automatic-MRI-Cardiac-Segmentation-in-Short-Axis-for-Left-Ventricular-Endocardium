function [bw4d_LV, bw3d_LV] = localizeLV_our(im4d)

%   disclaimer: this code is written by Tan, L.K., accessible on
%   github.com/tanlikuo/localizeLV

%   this is based from the paper Tan, L.K., Liew, Y.M., Lim, E. et al.
%   Automatic localization of the left ventricular blood pool centroid
%   in short axis cardiac cine MR images. Med Biol Eng Comput 56, 1053–1062
%   (2018). https://doi.org/10.1007/s11517-017-1750-7

%   localizeLV localizes cardiac LV by estimating 3D centrepoint
%
%   Estimates the cardiac left ventricle (LV) centre by roughly 
%   segmenting the LV bloodpool. Only works on MRI short-axis steady state 
%   free precession (SSFP) images.
%
%   [bw3d_LV, bw4d_LV] = localizeLV(im4d) 
%   in : im4d is a 4D volume with dimensions y,x,t,z

%   out: bw4d_LV is a 4D binary mask representing the estimated LV bloodpool
%   out: bw3d_LV is adapted from bw4d_LV, but averaged across time
%
%   NOTE: this function requires the MATLAB Image Processing and Statistics
%         toolboxes to be installed

% NOTE: This is based off a cleaned up version of TLK_findLV (dated 20160626).

% % % assert(nargin == 2, 'Function requires two input arguments.');
assert(ndims(im4d) == 4, 'Input volume must be 4D (y,x,z,t)');
% % % assert(isscalar(res_xy), 'x/y resolution should be scalar value');

%%% make our 4d image of double and read the size values of the size 
vol = double(im4d);
[sz_y, sz_x, sz_z, sz_t] = size(vol);

% get the DC (average) volume and the "minimum" (seed) volume
% will need it later
vol_dc = squeeze(mean(vol, 4));
vol_min = squeeze(min(vol, [], 4));

% calculate magnitude of 1st harmonic which highlights regions of significant motion,
% primarily the heart of each short axis slice location from base to apex.
h1_mag = goCalcH1_new(vol);

% use 1st harmonic motion to get initial mask
mask_valid = goThresholdMotion(h1_mag);

% get value for threshold segmentation
[mask_4d, thres_hilo, ~] = goThresholdVol(vol, h1_mag, mask_valid);
mask_dc = (vol_dc > thres_hilo) & mask_valid;
% we take the original cine stack and calculate the minimum intensity projection across
% time, Vmin, then threshold Vmin using tintensity
mask_min = (vol_min > thres_hilo) & mask_valid;

% localize the lung
[Cxy_lung, ~] = goCalcLungCxy(vol_dc, thres_hilo);

% separate and group "core" objects and "full" objects
% 8 = two-dimensional eight-connected neighborhood
% bwconncomp Find connected components in binary image
cc_full = bwconncomp(mask_4d, 8);
[info_full, px2d_full] = goParseBinaryObjs(cc_full);
cc_core = bwconncomp(mask_min, 8);
[info_core, px2d_core] = goParseBinaryObjs(cc_core);
% filter out noise / tiny objects (min 6 px)
arr = [ info_full.area ] < 6;
info_full(arr) = [];  px2d_full(arr) = [];  cc_full.PixelIdxList(arr) = [];  cc_full.NumObjects = sum(~arr);
arr = [ info_core.area ] < 6;
info_core(arr) = [];  px2d_core(arr) = [];  cc_core.PixelIdxList(arr) = [];  cc_core.NumObjects = sum(~arr);

% map out relationships between the "core" and "full" objects
[core2full, ~, f2c_num, core2core] = mapCore2Full(info_core, info_full, px2d_core, cc_full, sz_t);

% collect the connecting core objects into groups
[~, ~, conn_grp] = getCoreConnections(f2c_num, core2full, core2core, info_core);

% merge a subset of connected core objects together (targetting single
% objects which "break off" small chunks due to noise)
[cc_core_merged, cc_full_merged] = goMergeObjs(cc_core, cc_full, info_core, conn_grp, core2full);

% redo core <-> full object mapping. All remaining core-to-core connections
% should be between "significant" objects
cc_core = cc_core_merged;
cc_full = cc_full_merged;
[info_core, px2d_core] = goParseBinaryObjs(cc_core);
[info_full, px2d_full] = goParseBinaryObjs(cc_full);
[core2full, ~, f2c_num, core2core] = mapCore2Full(info_core, info_full, px2d_core, cc_full, sz_t);

% redo collection of the connecting core objects into groups
[~, ~, conn_grp] = getCoreConnections(f2c_num, core2full, core2core, info_core);

% split "full" objects in the remaining cases where there are still core
% connections
cc_full_split = goSplitObjs(cc_full, px2d_full, info_core, px2d_core, conn_grp, core2full);

% make final core <-> full object mapping, there should be no more connections / leaks between core objects 
cc_full = cc_full_split;
[info_full, px2d_full] = goParseBinaryObjs(cc_full);
[core2full, ~, f2c_num, core2core] = mapCore2Full(info_core, info_full, px2d_core, cc_full, sz_t);

% SCORE: get mean area and calculate normalized area range
% LV volume should be changing over time due to contraction and expansion of the heart
area_full_mean = zeros(length(info_core), 1);
scores_area = zeros(length(info_core), 1);
for n_core = 1:length(info_core)
    areas = [ info_full(core2full(n_core,:)).area ];
    area_full_mean(n_core) = mean(areas);
    scores_area(n_core) = max(areas) - min(areas);
end
scores_area = scores_area ./ area_full_mean;  % normalize by mean area

% SCORE: get average circularity / eccentricity
% the cross-sectional LV is generally circular in shape
cc = struct('Connectivity', 8, 'ImageSize', [sz_y  sz_x], 'NumObjects', length(info_full), 'PixelIdxList', []);
cc.PixelIdxList = px2d_full;
rp = regionprops(cc, 'Eccentricity');
eccen_full = [ rp.Eccentricity ];
scores_circ = zeros(length(info_core), 1);
for n_core = 1:length(info_core)
    scores_circ(n_core) = mean(eccen_full(core2full(n_core,:)));
end
scores_circ = 1 - scores_circ;  % invert so pure circle == 1

% SCORE: get distance from "dark centroid"
% the LV commonly neighbor regions of low intensity, particularly the
% lung, and therefore objects closer to lung tissue are assigned a higher score
Cx = permute(Cxy_lung(:,1), [3 2 1]);  Cy = permute(Cxy_lung(:,2), [3 2 1]);
[xx, yy, ~] = meshgrid(1:sz_x, 1:sz_y, 1:sz_z);
xx = bsxfun(@minus, xx, Cx);  yy = bsxfun(@minus, yy, Cy);
dist_map = sqrt( xx.^2 + yy.^2 );
dist_map = bsxfun(@minus, mean(mean(dist_map,1),2), dist_map);  % invert and normalize to average (possible) distance
dist_map(dist_map < 0) = 0;
% get minimum distance from each "core object" to inverse weighted centroid
scores_dist = zeros(length(info_core), 1);
for n_core = 1:length(info_core)
    scores_dist(n_core) = max(dist_map(cc_core.PixelIdxList{n_core}));
end

% SCORE (filter): check max centrepoint displacement in time
scores_ctrpnt = zeros(length(info_core), 1);
for n_core = 1:length(info_core)
    Cxy_all = vertcat( info_full(core2full(n_core,:)).Cxy );
    Cxy_med = median(Cxy_all, 1);
    Cxy_dist = sqrt( (Cxy_all(:,1) - Cxy_med(1)).^2 + (Cxy_all(:,2) - Cxy_med(2)).^2 );
    scores_ctrpnt(n_core) = max(Cxy_dist);
end
core_filt = false(length(info_core), 1);
core_filt(scores_ctrpnt > 15) = true;  % threshold at 15 mm

% get combined score, and apply some thresholds
scores = scores_area .* scores_circ .* scores_dist;
min_area = 400 ;  % set a 400 mm^2 minimum area threshold (value determined empirically)
scores(area_full_mean < min_area) = 0;
scores(core_filt) = 0;  % zero scores for objects that have been filtered out

% create "mean 3D object" for chaining calculations
px_mobj = cell(length(info_core), 1);
for n_core = 1:length(info_core)  % find pixels that are "active" at least 50% of cardiac phases
    px2d = vertcat( px2d_full{core2full(n_core, :)} );
    px_range = min(px2d):max(px2d);
    px_cnt = histc(px2d, px_range);
    px2d = px_range(px_cnt >= sz_t / 2);
    px_mobj{n_core} = px2d' + sz_x*sz_y*(info_core(n_core).slice - 1);  % apply z-offset
end
cc_mobj = struct('Connectivity', 8, 'ImageSize', [sz_y  sz_x  sz_z], 'NumObjects', length(info_core), 'PixelIdxList', []);
cc_mobj.PixelIdxList = px_mobj;
[info_mobj, px2d_mobj] = goParseBinaryObjs(cc_mobj);

% GROUPING: chain / group objects together
chains = goFindChains(scores, info_mobj, px2d_mobj, cc_mobj, core_filt, 1);
scores_chain = zeros(length(chains), 1);
for n_chn = 1:length(chains)
    scores_chain(n_chn) = sum(scores(chains{n_chn}));
end
idx_chain = find(scores_chain == max(scores_chain), 1, 'first');  % highest scoring chain / group

idx = core2full(chains{idx_chain}, :);  idx = idx(:);  % get matching 4D objects
arr = false(length(info_full), 1);  arr(idx) = true;
cc = cc_full;  cc.PixelIdxList(~arr) = {[]};
bw4d_LV = labelmatrix(cc) > 0;
bw3d_LV = squeeze( mean(bw4d_LV, 3) ) >= 0.5;

return  % convenience for setting breakpoints