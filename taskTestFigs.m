%% taskTest figs

load('E:\\TaskTest\\taskGazeStruct')

%create struct
for subj = 39:40
    
    subj
    load(sprintf('E:\\TaskTest\\subjData\\TaskTest_subj%d.mat',subj)); %load the files one by one

    for trialNum=1:length(fileArray)
        cd('E:\TaskTest\finalLibrary\task_test\task_test_all')
        myImage = imageArray{trialNum}; %screengrab from experiment(need whole screen for accurate eyelink points)
        fileName = fileArray{trialNum}; %image name

        %grab trial info
        [samplePosL,samplePosR,bothEyes,sampleTimes,trialTime,trialLength] = trialInfo(trialNum,eyelinkImportedData);
        
        task = char(taskArray(trialNum)); %our task
        task = strrep(task,' ','_'); %rename with _ so we can make it a struct name
        
        %make a struct for each image
        taskGazeData.(fileName).(task).(['Sub' num2str(subj)]) = bothEyes; %save the gazedata for botheyes in a struct labeled by filename and task type
    end
end
    
%% plot
cd('E:\TaskTest\finalLibrary\task_test\task_test_all')
sublist1=[1 4 5 8 10 11 13 16 17 20 22 24 25 28 30 32 33 36 38 40]
sublist2=[2 3 6 7 9 12 14 15 18 19 21 23 26 27 29 31 34 35 37 39]
load('E:\TaskTest\subjData\\taskTest_subj1.mat')
fgd1=[]
fgd2 = []

fig = imageArray{1};

myFixIm = zeros(size(fig)); % empty fixation image
binsize=10

x=0:binsize:(size(fig,2)-1); %make x and y the size of the image
y=0:binsize:(size(fig,1)-1); 

%raw gaze data
figure()
subplot(1,2,1)
imagesc(fig);
hold on
for i=sublist1
    gd1 = taskGazeData.bothroom99.Use_the_toilet.(sprintf('Sub%d', i));
    fgd1 = [fgd1;gd1];
    plot(gd1(:,1), gd1(:,2),'x')
end
title('Use the toilet')

subplot(1,2,2)
imagesc(fig);
hold on
for i=sublist2
    gd2 = taskGazeData.bothroom99.Wash_your_hands.(sprintf('Sub%d', i));
    fgd2 = [fgd2;gd2];
    plot(gd2(:,1), gd2(:,2),'x')
end
title('Wash your hands')

%heatmap version
figure()
subplot(1,2,1)
myFixIm1 = hist3(fgd1,{x,y})'; %histogram of every pixel that was fixated
myFixIm1 = imgaussfilt(myFixIm1,2);
imagesc(overlayHeatmap(fig,myFixIm1));
title('Use the toilet')

subplot(1,2,2)
myFixIm2 = hist3(fgd2,{x,y})'; %histogram of every pixel that was fixated
myFixIm2= imgaussfilt(myFixIm2,2);
imagesc(overlayHeatmap(fig,myFixIm2));
title('Wash your hands')