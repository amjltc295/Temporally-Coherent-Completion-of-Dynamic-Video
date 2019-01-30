function testTempGeoTform(videoData, videoFlow, opt)

[imgH, imgW, nCh, nFrame, nFlow] = size(videoFlow);

patchSize = 5; 
patchRad  = 5*floor(patchSize/2);
stride    = 40;

[X, Y, T] = meshgrid(patchRad+1:stride:imgW-patchRad, patchRad+1:stride:imgH-patchRad, 1:nFrame-1);
uvPixSub = cat(2, X(:), Y(:), T(:));

numUvPix = size(uvPixSub, 1);

[X, Y, T] = meshgrid(-patchRad: patchRad, -patchRad: patchRad, 0);
uvTrgRefPos = single(cat(2, X(:), Y(:), T(:)));

trgPatch = vc_prep_target_patch(videoFlow(:,:,:,:,1), uvPixSub, uvTrgRefPos);

pt1 = uvTrgRefPos(:,1:2);
tFormMat = zeros(3, 3, numUvPix);

% Compute transformation
for i = 1: numUvPix
    pt2 = trgPatch(:,:,i) + pt1;
    [tform,~,~,status] = estimateGeometricTransform(pt1, pt2, 'projective');
    tFormMat(:,:,i) = tform.T';
end

patchCorner = [-patchRad, -patchRad,0; patchRad, -patchRad,0; ...
    patchRad, patchRad, 0; -patchRad, patchRad, 0];
patchCorner = reshape(patchCorner', 1, 3, 4);
uvPatchPos  = bsxfun(@plus, uvPixSub, patchCorner);

% Visualize
for i = 1 : nFrame -1
    indPatchCur = uvPixSub(:,3) == i;
    uvPatchPosCur = uvPatchPos(indPatchCur,:,:);
    uvPixSubCur   = uvPixSub(indPatchCur, :);
    
    tFormMatCur   = tFormMat(:,:,indPatchCur);
    numUvPixCur   = size(uvPixSubCur, 1);
    
    uvPatchPosCurT = zeros(size(uvPatchPosCur));
    
    % Compute transformed positions
    patchCorner = squeeze(patchCorner);
    patchCorner(3,:) = 1;
    for j = 1: numUvPixCur
        p = patchCorner;
        pT = tFormMatCur(:,:,j)*p;
        pT = bsxfun(@rdivide, pT, pT(3,:));
        pT = bsxfun(@plus, pT, uvPixSubCur(j,:)');
        uvPatchPosCurT(j,:,:) = pT;
    end
    
    % Draw patch
    img1 = videoData(:,:,:,i);
    img2 = videoData(:,:,:,i+1);
    
    imgName1 = [opt.videoName, '_tform_', num2str(i,'%03d'), '_1.png'];
    imgName2 = [opt.videoName, '_tform_', num2str(i,'%03d'), '_2.png'];
    
    imgName1 = fullfile(opt.visResPath, imgName1);
    imgName2 = fullfile(opt.visResPath, imgName2);

    figure(2); imshow(img1); hold on;   
    for j = 1: numUvPixCur
        plot([uvPatchPosCur(j,1,1), uvPatchPosCur(j,1,2)], [uvPatchPosCur(j,2,1), uvPatchPosCur(j,2,2)], 'g-');
        plot([uvPatchPosCur(j,1,2), uvPatchPosCur(j,1,3)], [uvPatchPosCur(j,2,2), uvPatchPosCur(j,2,3)], 'g-');
        plot([uvPatchPosCur(j,1,3), uvPatchPosCur(j,1,4)], [uvPatchPosCur(j,2,3), uvPatchPosCur(j,2,4)], 'g-');
        plot([uvPatchPosCur(j,1,4), uvPatchPosCur(j,1,1)], [uvPatchPosCur(j,2,4), uvPatchPosCur(j,2,1)], 'g-');
    end
    hold off;
    export_fig(imgName1);
    
    figure(3); imshow(img2); hold on;   
    for j = 1: numUvPixCur
        plot([uvPatchPosCurT(j,1,1), uvPatchPosCurT(j,1,2)], [uvPatchPosCurT(j,2,1), uvPatchPosCurT(j,2,2)], 'g-');
        plot([uvPatchPosCurT(j,1,2), uvPatchPosCurT(j,1,3)], [uvPatchPosCurT(j,2,2), uvPatchPosCurT(j,2,3)], 'g-');
        plot([uvPatchPosCurT(j,1,3), uvPatchPosCurT(j,1,4)], [uvPatchPosCurT(j,2,3), uvPatchPosCurT(j,2,4)], 'g-');
        plot([uvPatchPosCurT(j,1,4), uvPatchPosCurT(j,1,1)], [uvPatchPosCurT(j,2,4), uvPatchPosCurT(j,2,1)], 'g-');
    end
    hold off;
    export_fig(imgName2);
    
    disp(['Processing frame ', num2str(i)]);
end

end