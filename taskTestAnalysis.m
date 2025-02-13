%% Task Test Analysis

%Differences in gaze patterns
%Heatmaps (created using PlacesCNN scene descriptions / GloVe semantic values)
%Compare mean semantic values

load('E:\TaskTest\GloVe_Heatmaps_mainWord')
load('E:\TaskTest\taskGazeStruct')

fileNames = fieldnames(taskGazeData);
height = 960; %height of all images as presented in exp
width = 1280; %width of all images as presented in exp
picSize = [height,width];
screenSize = [1920,1080]; %size of exp screen
CenterX = 960;
CenterY = 540;

%% Organize into matched and unmatched AUC scores by PICTURE
for scenes = 1:10
    scenes
    currentFile = taskGazeData.(char(fileNames(scenes))); %grab the two tasks for each file
    tasks = fieldnames(currentFile); %get the names of these tasks
    for t = 1:2
        gazeData = currentFile.(char(tasks(t))); %grab all the subj gaze data for this task
        for subj = 1:20 %up to 20 bc 2 tasks for 40 people (half got task a half got task b), by doing this inside the t loop we're effectively running through all 40 subjs (when t=2, the subj isn't the same as t=1, ie. t=1 subj=3 is actually subject #6)
            subjNames = fieldnames(gazeData); %grab subj struct names
            gd = gazeData.(char(subjNames(subj))); %gaze data for this subj
            
            %rectangle of the image (no gray background)
            rect = [(CenterX) - (width./2) (CenterY) - (height./2) width height]; %grab the rectangle that includes only the image (not the gray experiment background)
            rect = [rect(1), rect(2), rect(3)-1, rect(4)-1]; %subtract 1 pixel from width/height because matlab counts 0 as 1 (without this the dimensions would be 1 pixel too many)
    
            scale = (flip(screenSize(1:2)) - picSize(1:2)) / 2; %grab how many pixels on either side are gray background (y,x) for plotting later
            scaledEyePos = [gd(:,1)-scale(2),gd(:,2)-scale(1)]; %adjust eye positions so we can plot on just the image (no gray background)

            %% GloVe

            gloveMapIdx = find(strcmp(GloVeLibrary(1,:),char(fileNames(scenes)))); %find this file in our heatmap library
            gloveFilt = GloVeLibrary(2,gloveMapIdx); %grab this heatmap
            gloveFilt = gloveFilt{1,1};
            gloveFilt = imresize(gloveFilt,[picSize(:,1),picSize(:,2)]);

            %% ROC analysis 
            %True Positive Rate:
            %Sensitivity = True Positives / (True Positives + False Negatives)
            %True Positive Rate = Sensitivity

            %False Positive Rate:
            %Specificity = True Negatives / (True Negatives + False Positives)
            %False Positive Rate = 1-Specificity     

            myFixIm = zeros(picSize); % empty fixation image

            x=0:1:picSize(2)-1; %make x and y the size of the image
            y=0:1:picSize(1)-1;

            myFixIm = hist3(scaledEyePos,{x,y})'; %histogram of every pixel that was fixated       

            %         [score,tp,fp,allthreshes] = AUC_Judd(saliencyMap, fixationMap, jitter, toPlot)
            %         figure

            [gloveAUCMatch] = AUC_Judd(gloveFilt(:,:,t), myFixIm, 0, 0) %matched tasks and gaze           
            [gloveAUCOpp] = AUC_Judd(gloveFilt(:,:,(1-t+2)), myFixIm, 0, 0) %flip tasks 1 and 2, opposite tasks and gaze
            
            figure();
            p(1)=subplot(2,2,1.5);
            imagesc(imread(['E:\TaskTest\finalLibrary\pyPics\',char(fileNames(scenes)),'.jpg']));title('Scene Presented');
            set(gca,'XTick',[], 'YTick', []);originalSize1 = get(gca, 'Position'); %save the size of this so we can implement it to the colorbar images
            p(2)=subplot(2,2,3);
            imagesc(gloveFilt(:,:,t));title([strrep(char(tasks(t)),'_',' ') ' (Matched)']);hold on
            plot(scaledEyePos(:,1),scaledEyePos(:,2),'xr');colorbar;text(50,925,sprintf('AUC=%0.3f', gloveAUCMatch),'Color','w');
            set(gca,'XTick',[], 'YTick', []);originalSize2 = get(gca, 'Position'); %save the size of this so we can implement it to the colorbar images
            caxis([0 1]) %colorbar 0-1
            p(3)=subplot(2,2,4);
            imagesc(gloveFilt(:,:,(1-t+2)));title([strrep(char(tasks(1-t+2)),'_',' ') ' (Unmatched)']);hold on
            plot(scaledEyePos(:,1),scaledEyePos(:,2),'xr');colorbar;text(50,925,sprintf('AUC=%0.3f', gloveAUCOpp),'Color','w');
            set(gca,'XTick',[], 'YTick', []);originalSize3 = get(gca, 'Position'); %save the size of this so we can implement it to the colorbar images
            set(p(1), 'Position', originalSize1);set(p(2), 'Position', originalSize2);set(p(3), 'Position', originalSize3);
            caxis([0 1]) %colorbar 0-1
            
            gloveAUC_M(subj,t) = gloveAUCMatch; %matrix of matched scores for both tasks
            gloveAUC_O(subj,t) = gloveAUCOpp; %matrix of opposite scores for both tasks            
        end
    end
    GloVe_AUC.(char(fileNames(scenes))).matched = gloveAUC_M;
    GloVe_AUC.(char(fileNames(scenes))).opposite = gloveAUC_O;
end

%% Organize matched/unmatched AUC scores by SUBJECT
fNames = fieldnames(taskGazeData); %filenames
for f = 1:10
    tNames = fieldnames(taskGazeData.(char(fNames(f)))); %tasknames
    for t = 1:2
        sNames = fieldnames(taskGazeData.(char(fNames(f))).(char(tNames(t)))); %subjnames
        mScores = GloVe_AUC.(char(fNames(f))).matched(:,t); %matched lsaScores
        oScores = GloVe_AUC.(char(fNames(f))).opposite(:,t); %opposite lsaScores
        for s = 1:20
            subj_GloVe_AUC.(char(sNames(s))).matched(f) = mScores(s); %struct sorted by subj of matched AUC scores
            subj_GloVe_AUC.(char(sNames(s))).opposite(f) = oScores(s); %struct sorted by subj of opposite AUC scores
        end
    end
end

%reorder
for c=1:40
    C(c) = {sprintf('Sub%d',c)};
end
subj_GloVe_AUC = orderfields(subj_GloVe_AUC,C);


%% Do some stats

load('E:\TaskTest\subj_GloVe_AUC_multWord')

%Find avg matched score for each subj
for s = 1:40
    sNames = fieldnames(subj_GloVe_AUC);
    subj_mScores(s) = nanmean(subj_GloVe_AUC.(char(sNames(s))).matched); %find avg matched score for each subj 
    subj_oScores(s) = nanmean(subj_GloVe_AUC.(char(sNames(s))).opposite); %find avg opposite score for each subj 
end

[h,p,ci,stats] = ttest(subj_mScores,subj_oScores) %paired ttest

if p > .05
    str = sprintf('t(%d)=%0.3f; p=%0.3f',stats.df,stats.tstat,p)
elseif p < .05 && p > .01
    str = sprintf('t(%d)=%0.3f; p<0.05*',stats.df,stats.tstat)
elseif p < .01 && p > .001
   str = sprintf('t(%d)=%0.3f; p<0.01**',stats.df,stats.tstat)
elseif p < .001
    str = sprintf('t(%d)=%0.3f; p<0.001***',stats.df,stats.tstat)
elseif isnan(p)
    str = {'-'}
end
        
%% Figures
addpath('E:\sigstar')

figure();
coordLineStyle = 'k.'; %define how we want our outliers to be marked (black points), will be overlapped by individual data points later
boxplot([subj_mScores',subj_oScores'], 'Symbol', coordLineStyle, 'Labels',{'Matched','Unmatched'}); hold on;
parallelcoords([subj_mScores',subj_oScores'], 'Color', 0.7*[1 1 1], 'LineStyle', '-',...
  'Marker', '.', 'MarkerSize', 10); %parallelcoords will plot the individual points of the two column vector [subj_mScores',subj_oScores'] and draw lines connecting individual points between the two boxplots
title('Semantic AUC Scores')
% text(0.6,0.49,str) %include stats
sigstar([1,2],.0001)
plot([1,2],[nanmean(subj_mScores),nanmean(subj_oScores)],'Color','black','LineWidth',1) %plot overall mean line on top in a bolder black
ylabel('AUC')

%% quick descriptive stats on missing data

missing=0;

for i = 1:10
    fNames = fieldnames(taskGazeData); %filenames
    taskNames = fieldnames(taskGazeData.(char(fNames(i)))); %tasknames
    for t = 1:2
        sNames = fieldnames(taskGazeData.(char(fNames(i))).(char(taskNames(t))));
        for s = 1:20
            n = isnan(taskGazeData.(char(fNames(i))).(char(taskNames(t))).(char(sNames(s))));
            if sum(n(:))==2*length(n); %if all cases are nans, this was a missed trial
                missing = missing+1;
                i
                t
                s
            end
        end
    end
end

missing/(i*t*s)

%% Effect size

effect = (mean(subj_mScores) - mean(subj_oScores)) / std(subj_mScores - subj_oScores)
d = computeCohen_d(subj_mScores, subj_oScores, 'paired') %check for sanity

%% power
pwrout = sampsizepwr('t',[.05 .0291],[],.95,40)