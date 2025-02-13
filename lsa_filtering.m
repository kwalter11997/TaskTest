%% lsa_filtering

cd('E:\TaskTest')
sceneDes = readtable('task_list.xlsx'); 

cd('E:\TaskTest\FinalLibraryPyPics')
D = dir; 
D = D(~ismember({D.name}, {'.', '..'})); %first elements are '.' and '..' used for navigation - remove these
fileNames = {D.name}; %get all the file names
 
load('E:\TaskTest\subjData\taskTest_subj1') %load in any subject so we can grab the size array matrix (size of iamges as they appeared in the exp)

fileSizes = [fileArray;num2cell(sizeArray)]; %make a matrix of filesizes how they appeared in the experiment (with filenames)

%screen info
scrnWidthPx = 1920; %screen width pixels
scrnWidthCm = 60; %screen width cm
viewDistCm = 63; %viewing distance of participants
%get visual angle info for error that should be applied via gaussian
scrnWidthDeg=2*atand((0.5*scrnWidthCm)/viewDistCm); %calculate screen width in degrees
pxperdeg = scrnWidthPx/scrnWidthDeg; %get number of pixels per degree
pxError = .375*pxperdeg; %multiply pixel per degree by average degree error (.375 taken from estimate of 0.25-0.50 from Eyelink Manual) to get the number of pixels in the estimated manufacturer error

%create some empty variables to save the maps in later
LSALibrary = {};

for f = 1:10
    f
    fileNameFull = fileNames{f};
    fileNameShort = erase(fileNameFull,'.jpg');
    myImage = imread(fileNameFull);
    sizeIdx = find(strcmp(fileSizes(1,:),fileNameShort)); %find which cell in our filesizes matrix contains the info about this image
     
    %% LSA

    queryList = sceneDes.(fileNameShort);
    [semanticIm] = LSA(fileNameShort, myImage, queryList); %get the LSA (semantic relevance) map
    lsaFilt = imresize(semanticIm,[sizeArray(2,sizeIdx),sizeArray(1,sizeIdx)]);  %resize filter to fit our smaller experiment picture
    lsaFilt = imgaussfilt(lsaFilt,pxError); %add a gaussian of the eyetracker error
    lsaFiltA = lsaFilt(:,:,1); %split so we can normalize seperately
    lsaFiltB = lsaFilt(:,:,2);
    lsaFiltA = (lsaFiltA - min(lsaFiltA(:))) / (max(lsaFiltA(:)) - min(lsaFiltA(:))); %normalize
    lsaFiltB = (lsaFiltB - min(lsaFiltB(:))) / (max(lsaFiltB(:)) - min(lsaFiltB(:))); %normalize
    lsaFilt = cat(3,lsaFiltA,lsaFiltB); %recombine for ease of saving
%     
%     figure()
%     subplot(1,2,1)
%     imagesc(lsaFilt(:,:,1))
%     title(queryList(1))
%     subplot(1,2,2)
%     imagesc(lsaFilt(:,:,2))
%     title(queryList(2))

    LSALibrary(1,f) = {fileNameShort};
    LSALibrary(2,f) = {lsaFilt};
    
end

SAVE = 'E:\TaskTest';
cd(SAVE)
savefile = 'LSA_Heatmaps';
save(savefile,'LSALibrary')
