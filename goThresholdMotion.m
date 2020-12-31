function mask = goThresholdMotion(vol)
% use 1st harmonic motion to get initial mask

[sz_y, sz_x, sz_z] = size(vol);
vol = imfilter(vol, fspecial('average'));
pd = fitdist(vol(:), 'Exponential');
vol(vol < icdf(pd, 0.95)) = 0;  % threshold at p=0.95
thres = prctile(vol(vol > 0), 99);
vol(vol > thres) = thres;  % threshold at max 99%

ctr3d_xy = zeros(1, 3);
[xx, yy, zz] = meshgrid(1:sz_x, 1:sz_y, 1:sz_z);
max_iter = 5;  % maximum allowed iterations
for n = 1:max_iter  
    % Get 2D weighted centroid (should be identical to regionprops)
    xx_wt = xx .* vol;  yy_wt = yy .* vol;  zz_wt = zz .* vol;
    ctr_xy = [ squeeze( sum(sum(xx_wt,1),2) )  squeeze( sum(sum(yy_wt,1),2) ) ];
    vol_sum = squeeze( sum(sum(vol,1),2) );
    ctr_xy = ctr_xy ./ [ vol_sum  vol_sum ];
    
    slices = 1:sz_z;
    arr = all(~isnan(ctr_xy), 2);  % check for invalid cases (i.e., no valid pixels)
    
    % NOTE: not very sure if this is the best way... it appears that svd is
    % more appropriate?
    px = polyfit(slices(arr), ctr_xy(arr,1)', 1);  % get x/y line of best fit
    py = polyfit(slices(arr), ctr_xy(arr,2)', 1);

    ctr_xy_fit = [ polyval(px, 1:sz_z)'  polyval(py, 1:sz_z)' ];  % fitted centrepoints
    
    % get 3D weighted centroid and compare distance from previous 3D centroid
    % (should be identical to MATLAB's regionprops)
    ctr3d_new = [ sum(xx_wt(:))  sum(yy_wt(:))  sum(zz_wt(:)) ] / sum(vol(:));
    ctr3d_diff = ctr3d_xy - ctr3d_new;
    ctr3d_diff = sqrt(sum(ctr3d_diff.^2));
    ctr3d_xy = ctr3d_new;
    
    if ctr3d_diff < 1;  % stop iteration when 3D centroid differs by < 1 px
        break;
    elseif n == max_iter
        fprintf('Warning: 3D centroid did not stabilize\n');
    end  
    
    % calculate the distance from every voxel to its 2D centroid
    diff_xx = bsxfun(@minus, xx, shiftdim(ctr_xy_fit(:,1), -2));
    diff_yy = bsxfun(@minus, yy, shiftdim(ctr_xy_fit(:,2), -2));
    vol_dist = sqrt(diff_xx.^2 + diff_yy.^2);
    
    % calculate combined intensity & distance index (higher intensity &
    % shorter distance is better)
    vol_comb = vol_dist .* (max(vol(:)) - vol);  % invert intensity to be compatible w/ distance
    vol_samp = vol_comb((vol > 0) & (vol_comb > 0));  % remove ommited voxels. Also, a few distributions don't allow zero values

    % the distribution is strictly positive, with a long tail to the right
    % a bunch of distributions match reasonably well, in order:
    % LogLogistic, Gamma, Weibull, Nakagami, Rayleigh
    % The first 2 fit better, while the last 3 are more "rounded/damped"
    pd = fitdist(vol_samp, 'LogLogistic');
    vol(vol_comb > pd.icdf(0.9)) = 0;  % threshold at one-tailed p = 0.9
end

% construct final mask
xx = xx(:,:,1);  yy = yy(:,:,1);
mask = vol > 0;
for n = 1:sz_z
    mask2d = mask(:,:,n);
    if ~any(mask2d(:));  continue;  end
    
    Cxy_all = [ mean(xx(mask2d))  mean(yy(mask2d)) ];
    cc = bwconncomp(mask2d);
    if cc.NumObjects == 1;  continue;  end
    
    px_areas = cellfun(@numel, cc.PixelIdxList);
    cc_dist = zeros(cc.NumObjects, 1);
    for n_cc = 1:cc.NumObjects
        Cxy = [ mean(xx(cc.PixelIdxList{n_cc}))  mean(yy(cc.PixelIdxList{n_cc})) ];
        cc_dist(n_cc) = sqrt(sum( (Cxy - Cxy_all).^2 ));
    end
    
    score = ( px_areas' / max(px_areas) + 1 - (cc_dist / max(cc_dist)) ) / 2;
    cc_all = cc;
    cc_all.NumObjects = 1;
    cc_all.PixelIdxList = { vertcat( cc.PixelIdxList{score >= .01} ) };
    rp = regionprops(cc_all, 'BoundingBox', 'ConvexImage', 'ConvexArea');
    mask2d = false(sz_y, sz_x);
    bb = round( rp.BoundingBox );
    bb_x = [ bb(1)  bb(1) + bb(3) - 1 ];
    bb_y = [ bb(2)  bb(2) + bb(4) - 1 ];
    mask2d(bb_y(1):bb_y(2), bb_x(1):bb_x(2)) = rp.ConvexImage;
    
    mask(:,:,n) = mask2d;
end