function srcPos = vc_get_spatial_propagation(srcPos, srcTfmG, propDir)

% Predict the spatial neighbors using the geometric transformation srcTfmG
offsetVec = vc_apply_affine_tform(srcTfmG, propDir);
srcPos(:,1:2) = srcPos(:,1:2) + offsetVec;

end
