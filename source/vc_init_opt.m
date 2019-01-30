function opt = vc_init_opt(videoName)
%
% VC_INIT_OPT
%
% Initialize algorithm parameters

fprintf('Initialize parameters \n');

% =========================================================================
% Patch size
% =========================================================================
opt.pSize = 5;                       % Patch size (odd number), use larger patch for more coherent region
opt.pRad  = floor(opt.pSize/2);      % Patch radius
opt.pMidPix = round(opt.pSize*opt.pSize/2);  % The center of the patch
opt.spPatchSize = opt.pSize*opt.pSize; % Spatial patch size

% =========================================================================
% Multi-resolution parameters
% =========================================================================
opt.numPyrLvl      = 5;               % Number of coarse to fine layer
opt.coarestImgSize = 32;              % The size of the smallest image in the pyramid
opt.useLogScale    = 1;               % Use log scales (1) or linear scales (0) for downsampling
opt.topLevel       = 1;               % Which level to stop

% =========================================================================
% Number of iterations per pyramid level
% =========================================================================
opt.numIter    = 10;                  % The initial iteration number
opt.numIterDec = opt.numIter/opt.numPyrLvl;
opt.numIterMin = 1;                   % The minimum iteration number
opt.numPassPerIter = 1;                 
opt.numAltIter = 2;

% =========================================================================
% Method configuration
% =========================================================================
opt.useFwFlow = true;                     % Use forward flow cost
opt.useBwFlow = true;                     % Use backward flow cost

opt.useCoherence = true;                  % Use spatial coherence cost
% opt.useBiasCorrection = false;          % Use bias correction
% opt.useGtOccMask = false;               % Use groundtruth occlusion mask (MPI only)

opt.usePredBiasMap  = false;            % Use temporal bias prediction

opt.usePoissonBlend = false;            % 3D Poisson blending

opt.visResFlag      = true;

% Temporal weighting parameters
opt.useConfWeight  = false;             % Flow confidence weight
opt.useOccWeight   = false;            % Flow occlusion-aware weight

% =========================================================================
% PatchMatch Propagation
% =========================================================================
opt.propDir = single([1, 0, 0; 0,  1,  0 ; ...
    -1, 0, 0; 0, -1,  0 ; ...
    0, 0, 1; 0,  0, -1]);
opt.spatialPropInd  = 1:4;
opt.temporalPropInd = 5:6;

% =========================================================================
% Source patch transformation parameters
% =========================================================================
% Source patch geometric transformation parameters
opt.srcScaleSearchRad =  1*0.2;
opt.srcRotSearchRad   =  1*pi/4;
opt.srcShSearchRad    =  0*0.0;
opt.srcTfmRad         = [opt.srcScaleSearchRad,opt.srcRotSearchRad,opt.srcShSearchRad];
opt.minSearchRad      =  1;

% Min/max patch scale
opt.maxPatchSc   = 1.2;
opt.minPatchSc   = 0.8;

% =========================================================================
% Patch matching weight
% =========================================================================
opt.wDist   = 2.^linspace(0, 1, opt.numPyrLvl);   % Distance-based weights
opt.wSigmaM = 3;                                  % Gaussian weight for matching
opt.wSigmaR = 1;                                  % Gaussian weight for reconstruction

% Patch cost parameters
opt.lambdaColor = 1;                              % Color matching weight
opt.lambdaFlow  = 1e3;                            % Flow matching weight

opt.lambdaCoherence = 1e-4;                       % Coherence weight

opt.wSpPatch = 1;

% opt.alphaT  = 0.25;                               % Temporal averaging weight
opt.alphaT  = 0.1;                               % Temporal averaging weight

% =========================================================================
% Video pathes
% =========================================================================
opt.videoName = videoName;
opt.time = datetime;

% Create directories
vc_create_video_dir(videoName, opt.time);

% dateStr = [num2str(opt.time.Year), '-', num2str(opt.time.Month, '%02d'), '-', num2str(opt.time.Day, '%02d'),' '];
% videoNameDate = [dateStr, videoName];
videoNameDate = videoName;

opt.resPath = 'result/completion_ours';
opt.flowResPath   = fullfile(opt.resPath, videoNameDate,  'flow');
opt.colorResPath  = fullfile(opt.resPath, videoNameDate,  'color');
opt.iterResPath   = fullfile(opt.resPath, videoNameDate,  'iter');
opt.iterSpResPath = fullfile(opt.resPath, videoNameDate,  'iter_sp');
opt.visResPath    = fullfile(opt.resPath, videoNameDate,  'visual');

opt.visFlowConfResPath = fullfile(opt.visResPath, 'flowConf');
opt.visDistResPath     = fullfile(opt.visResPath, 'distMap');
opt.visFlowErrResPath  = fullfile(opt.visResPath, 'flowErr');

if(~exist(opt.visFlowConfResPath, 'dir'))
    mkdir(opt.visFlowConfResPath);
end

if(~exist(opt.visFlowErrResPath, 'dir'))
    mkdir(opt.visFlowErrResPath);
end


opt.flowDataPath =  fullfile('cache/flowData', videoName);
if(~exist(opt.flowDataPath, 'dir'))
    mkdir(opt.flowDataPath);
end

end

function vc_create_video_dir(videoName, t)
% ====================================================================
% Create result path
% ====================================================================

if(~exist('result', 'dir'))
    mkdir('result')
end

% dateStr   = [num2str(t.Year), '-', num2str(t.Month, '%02d'), '-', num2str(t.Day, '%02d'),' '];
% videoName = [dateStr, videoName];

% ====================================================================
% Create flow, color, iter, iter_sp, and visual paths
% ====================================================================

resPath = 'result/completion_ours';
if(~exist(fullfile(resPath, videoName), 'dir'))
    mkdir(fullfile(resPath, videoName))
end

flowResPath = fullfile(resPath, videoName, 'flow');
if(~exist(flowResPath, 'dir'))
    mkdir(flowResPath);
end

colorResPath = fullfile(resPath, videoName, 'color');
if(~exist(colorResPath, 'dir'))
    mkdir(colorResPath);
end

iterResPath = fullfile(resPath, videoName, 'iter');
if(~exist(iterResPath, 'dir'))
    mkdir(iterResPath);
end

iterSpResPath = fullfile(resPath, videoName, 'iter_sp');
if(~exist(iterSpResPath, 'dir'))
    mkdir(iterSpResPath);
end

visResPath = fullfile(resPath, videoName, 'visual');
if(~exist(visResPath, 'dir'))
    mkdir(visResPath);
end

% ====================================================================
% Create flow consistency and keyframe directories
% ====================================================================
% visFlowResPath     = fullfile(visResPath, 'flow');
% if(~exist(visFlowResPath, 'dir'))
%     mkdir(visFlowResPath);
% end
%
% visKeyFrameResPath = fullfile(visResPath, 'keyframe');
% if(~exist(visKeyFrameResPath, 'dir'))
%     mkdir(visKeyFrameResPath);
% end
%

% ====================================================================
% Create flow data cache folder
% ====================================================================
if(~exist('cache', 'dir'))
    mkdir('cache');
end

flowDataPath = 'cache/flowData';
if(~exist(flowDataPath, 'dir'))
    mkdir(flowDataPath);
end

end