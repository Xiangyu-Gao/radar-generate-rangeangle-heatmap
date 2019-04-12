clc;
clear all;
close all;
%% parameter setting
fc = 78.5e9;                                  % Center frequency (Hz)
Fs=10^7;
sweepSlope=49.9700e12;                      %%%
samples=256;
loop=128;
Frame_num=2;
Rx=4;
Tx=2;

fft_Rang=256;
fft_Vel=128;
fft_Ang=181;
%% data analysis
data=readTSW14xx('C:\Users\Administrator\Desktop\Radar\data\adc_data_20180925_5.bin');
data_length=length(data);
data_each_frame=data_length/Frame_num;
% data_all=reshape(data',size(data,1)*size(data,2),[]);  %%%%reshape 4 channels into 1
for i=1:Frame_num
Framedata(:,:,i)=data(:,((i-1)*data_each_frame+1):i*data_each_frame);
Frame(:,i)=reshape(Framedata(:,:,i).',size(Framedata(:,:,i),1)*size(Framedata(:,:,i),2),[]);  %%%%reshape 4 channels into 1
Frame_loop(:,:,i)=reshape(Frame(:,i),samples,[]);
Frame_loop_chirp1(:,:,i)=Frame_loop(:,1:2:end,i);
Frame_loop_chirp2(:,:,i)=Frame_loop(:,2:2:end,i);

Frame_loop_chirp1_Rx(:,:,:,i)=reshape(Frame_loop_chirp1(:,:,i),[samples loop Rx]);
Frame_loop_chirp2_Rx(:,:,:,i)=reshape(Frame_loop_chirp2(:,:,i),[samples loop Rx]);

Xcube_chirp1=permute(Frame_loop_chirp1_Rx(:,:,:,i),[1 3 2]);
Xcube_chirp2=permute(Frame_loop_chirp2_Rx(:,:,:,i),[1 3 2]);
Xcube_chirp3=[Xcube_chirp1 Xcube_chirp2];
[Rangedata_chirp1]=fft_Radar(Xcube_chirp1,fft_Rang,fft_Vel,fft_Ang);
[Rangedata_chirp2]=fft_Radar(Xcube_chirp2,fft_Rang,fft_Vel,fft_Ang);
[DopData AngleData Rangedata]=afft_Radar(Xcube_chirp3,fft_Rang,fft_Vel,fft_Ang);
[rnggrid dopgrid anggrid]=plot_fftdata(Xcube_chirp3,DopData,AngleData,fc,Fs,sweepSlope);

end

% plot(real(Frame2_loop_chirp1_Rx(:,1,1)));
%%% First fft on range dimension

Xcube=[Xcube1 Xcube2];    %%%%tx2--rx2



% save testdata_adc_data_20181005_tworeflector_5.mat Xcube DopData AngleData Rangedata
% load testdata_adc_data_20180624_1_2.mat;
Nr=512;

%% CFAR
% Guard cell and training regions for range dimension
Nd=fft_Vel;
Nr=fft_Rang;
nGuardRng = 4;
nTrainRng = 4;
nCUTRng = 1+nGuardRng+nTrainRng;
% Guard cell and training regions for Doppler dimension
Nsweep=Nd;
dopOver = round(Nd/Nsweep);
nGuardDop = 4*dopOver;
nTrainDop = 4*dopOver;
nCUTDop = 1+nGuardDop+nTrainDop;

cfar = phased.CFARDetector2D('GuardBandSize',[nGuardRng nGuardDop],...
    'TrainingBandSize',[nTrainRng nTrainDop],...
    'ThresholdFactor','Custom','CustomThresholdFactor',db2pow(18),...
    'NoisePowerOutputPort',true,'OutputFormat','Detection index');

% Perform CFAR processing over all of the range and Doppler cells
freqs = ((0:Nr-1)'/Nr-0.5)*Fs;
rnggrid = beat2range(freqs,sweepSlope);
iRngCUT = find(rnggrid>0);
iRngCUT = iRngCUT(iRngCUT<=Nr-nCUTRng+1);
iDopCUT = nCUTDop:(Nd-nCUTDop+1);
[iRng,iDop] = meshgrid(iRngCUT,iDopCUT);
idxCFAR = [iRng(:) iDop(:)]';
Xbf=squeeze(DopData(:,1,:));
Xpow=abs(Xbf);
[detidx,noisepwr] = cfar(Xpow,idxCFAR);
clusterIDs = clusterDetections(detidx);
rngest=point_estimator(Xbf,rnggrid,detidx,noisepwr,clusterIDs)
dopest=point_estimator(Xbf,dopgrid,detidx,noisepwr,clusterIDs)

figure(1)
hold on
str=[repmat('Velocity:',length(dopest),1) num2str(dopest') ,repmat(sprintf('\n'),length(dopest),1), repmat('Range:',length(rngest),1) num2str(rngest')];
text(dopest,rngest,' ','EdgeColor','w','backgroundcolor','k','FontSize',0.5,'layer','front')
text(dopest,rngest,cellstr(str),'Color','k','EdgeColor','k','backgroundcolor','[1 1 0.9]','FontSize',10,'layer','front')



% [rngest,rsvar]= rngestimator(Xbf,rnggrid,detidx,noisepwr,clusterIDs);
% [rsest,rsvar] = dopestimator(Xbf,dopgrid,detidx,noisepwr,clusterIDs);
j=1;

function est=point_estimator(data,grid,detidx,noisepwr,clusterIDs)

clusters = unique(clusterIDs);
numClusters = numel(clusters);

dimLen=length(grid);
szResp=size(data);
dim=find(szResp==dimLen);
    for m = 1:numClusters
        thiscluster = find(clusterIDs==clusters(m));       
        % Find peak in cluster
        idx = sub2ind(szResp,detidx(1,thiscluster),detidx(2,thiscluster));
         y = data(idx);
         [mVal,iMax] = max(abs(y(:)));
         [idx1,idx2] = ind2sub(szResp,idx(iMax));
          switch dim
              case 2
                idx2 = idx2+(-1:1)';
                idx2 = idx2(idx2>0&idx2<=dimLen);
                idx1 = repmat(idx1,numel(idx2),1);
                x = grid(idx2);
               case 1
                 idx1 = idx1+(-1:1)';
                 idx1 = idx1(idx1>0&idx1<=dimLen);
                 idx2 = repmat(idx2,numel(idx1),1);
                 x = grid(idx1);
                end
         iEst = sub2ind(szResp,idx1,idx2);
         y = abs(data(iEst));
          if numel(y)<3 % Centroid interpolation
              est(m) = sum(x(:).*y(:))/sum(y);
          else % Quadratic interpolation
              den = 2*y(2)-y(1)-y(3);
              if den~=0
                 delta = 0.5*(y(3)-y(1))/den;
               if delta>0.5
                  delta = 0.5;
                 elseif delta<-0.5
                  delta = -0.5;
               end
              else
                  delta= 0;
              end
            est(m) = x(2)+delta*(x(2)-x(1));
           end
    end
end


function clusterIDs = clusterDetections(detidx)
% clusterIDs = clusterDetections(dets) clusters detections from a
% range-Doppler image. Detections which occur at adjacent range and Doppler
% cells within the image are associated to a single detection cluster. Each
% detection cluster is assigned a unique cluster ID which is used to
% identify the detections assigned to that cluster.
%
% detidx is a 2-by-L matrix of detection indices. Each column of detidx
% identifies the range and Doppler cell in the range-Doppler image where a
% detection was found as [rngidx; dopidx].
%
% clusterIDs is a 1-by-L vector of cluster IDs assigned to each detection
% index in detidx.

% Number of detections found in the range-Doppler image
numDet = size(detidx,2);
clusterIDs = NaN(1,numDet);

iGd = ~isnan(detidx(1,:));
if any(iGd(:))
    % Cluster adjacent points
    iRng = detidx(1,iGd);
    iDop = detidx(2,iGd);
    
    iGroups = cell(1,0);
    allCells = [iRng;iDop];
    while ~all(isnan(allCells(1,:)))
        % Select an unassigned range-Doppler cell and remove it from the set
        iFnd = find(~isnan(allCells(1,:)),1);
        thisCell = allCells(:,iFnd);
        allCells(:,iFnd) = NaN;
        
        % Find all cells adjacent to the selected cell and remove them from set
        [iAdjCells,allCells] = findAdjacentCells(allCells,thisCell);
        
        iGroups{end+1} = [iFnd iAdjCells]; %#ok<AGROW>
    end
    
    % Assign unique cluster IDs to each group of adjacent range-Doppler
    % cells
    ids = NaN(sum(iGd),1);
    for m = 1:numel(iGroups)
        ids(iGroups{m}) = m;
    end
    clusterIDs(iGd) = ids';
end
end

function [iAdjCells,allCells] = findAdjacentCells(allCells,thisCell)
% [iAdjCells,allCells] = findAdjacentCells(allCells,thisCell) finds the
% cells in the 2-by-L matrix of allCells that are adjacent to the 2-by-1
% vector for the current cell, thisCell. Both allCells and thisCell contain
% indices of the rows and columns of a matrix.
%
% iAdjCells is a 2-by-M matrix of cells in allCells that are adjacent to
% thisCell. M is less-than or equal-to L.
%
% allCells is returned as a 2-by-L matrix, where the adjacent cells
% returned in iAdjCells have been set to NaN.

% Find all cells adjacent to the current cell and remove it from the set
delta = allCells-repmat(thisCell,[1 size(allCells,2)]);
iAdjCells = find(all(abs(delta)<=2,1));
thisCell = allCells(:,iAdjCells);
allCells(:,iAdjCells) = NaN;

% Find call cells next to each of the adjacent cells that were just found
for m = 1:numel(iAdjCells)
    [iAdjNext,allCells] = findAdjacentCells(allCells,thisCell(:,m));
    iAdjCells = [iAdjCells iAdjNext]; %#ok<AGROW>
end
end


