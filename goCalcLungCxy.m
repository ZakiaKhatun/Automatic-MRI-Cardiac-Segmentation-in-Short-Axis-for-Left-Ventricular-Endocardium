function [Cxy_lung, bw3d_valid] = goCalcLungCxy(vol_dc, thres_hilo)
% now try to detect the lung (actually just the dark areas)
[sz_y, sz_x, sz_z] = size(vol_dc);

% calculate the "valid area" by omitting the background air and limbs
bw3d_high = vol_dc >= thres_hilo;
bw3d_valid = bw3d_high;
[xx, yy] = meshgrid(1:sz_x, 1:sz_y);
for n_z = 1:sz_z
    % get centrepoint of binary "bright" image
    bw = bw3d_valid(:,:,n_z);
    Cxy = [ mean(xx(bw))  mean(yy(bw)) ];
    d_map = sqrt( (xx - Cxy(1)).^2 + (yy - Cxy(2)).^2 );
    
    cc = bwconncomp(bw);
    if cc.NumObjects == 0;  continue;  end
    
    % calculate the maximum convex hull area
    cc_full = cc;
    cc_full.NumObjects = 1;
    cc_full.PixelIdxList = { vertcat(cc_full.PixelIdxList{:}) };
    rp = regionprops(cc_full, 'ConvexHull', 'ConvexArea');
    area_max = rp.ConvexArea;
    bw = roipoly(bw, rp.ConvexHull(:,1), rp.ConvexHull(:,2));
    
    % calculate the distance of each "bright" object from the binary centrepoint
    d_list = zeros(cc.NumObjects, 1);
    for n = 1:cc.NumObjects
        d_list(n) = min( d_map(cc.PixelIdxList{n}) );
    end
    [~, idx] = sort(d_list);
    cc.PixelIdxList = cc.PixelIdxList(idx);
    
    % starting from the closest-to-centre object, keep adding objects until
    % the combined convex hull is 75% of the maximum
    cc_sub = cc_full;
    cc_sub.PixelIdxList = { [] };
    for n = 1:cc.NumObjects
        cc_sub.PixelIdxList{1} = vertcat(cc_sub.PixelIdxList{1}, cc.PixelIdxList{n});
        rp = regionprops(cc_sub, 'ConvexHull', 'ConvexArea');
        if rp.ConvexArea / area_max >= 0.75  % area threshold 75%
            bw = roipoly(bw, rp.ConvexHull(:,1), rp.ConvexHull(:,2));
            break
        end
    end
    bw3d_valid(:,:,n_z) = bw;
end

% calculate the weighted centroid of the dark regions
[xx, yy] = meshgrid(1:sz_x, 1:sz_y);
ctr_x = zeros(sz_z, 1);  ctr_y = zeros(sz_z, 2);
ctr_x(:) = sz_x/2;  ctr_y(:) = sz_y/2;  % default to centre of image
for n_z = 1:sz_z
    im = vol_dc(:,:,n_z);
    bw = bw3d_valid(:,:,n_z)  &  ~bw3d_high(:,:,n_z);
    if ~any(bw(:));  continue;  end
    im = max(im(bw)) - im;
    im(~bw) = 0;
    im = im .^ 2;  % emphasize the darker intensities
    xx_wt = xx .* im;  yy_wt = yy .* im;
    ctr_x(n_z) = sum(xx_wt(:)) / sum(im(:));
    ctr_y(n_z) = sum(yy_wt(:)) / sum(im(:));
end

Cxy_lung = [ ctr_x  ctr_y ];