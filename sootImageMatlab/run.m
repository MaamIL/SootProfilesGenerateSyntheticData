%This is an example main file. Running it creates the images of the Gulder
%flame as described in the paper (full version afther the review will
%include doi)
function run(currentSubDir)
%clear

%load the calculation and camera data;


%load sootCalculation.mat;

load(fullfile(currentSubDir, 'sootCalculation.mat'));
load cameraSpectralResponse.mat;
pixelSize = 0.0662;
IntensityCalibration = [0.007239779, 0.007340223, 0.008730818];

%Build CFD Image
[redMatrixCFD, greenMatrixCFD, blueMatrixCFD] = buildPicture(T, fv, r, z, cameraSpectralResponse(1:51,:), pixelSize, IntensityCalibration);
CFDImage(:,:,1) = redMatrixCFD;
CFDImage(:,:,2) = greenMatrixCFD;
CFDImage(:,:,3) = blueMatrixCFD;
CFDImage = flipud(CFDImage); %For images the y axis goes down and not up.
save('CFDImage.mat', 'CFDImage');

% Save individual matrices
%saveFileName = fullfile(currentSubDir, ['matrices_' subDirs(i).name '.mat']);
save(fullfile(currentSubDir, 'redMatrixCFD.mat'), 'redMatrixCFD');
save(fullfile(currentSubDir,'greenMatrixCFD.mat'), 'greenMatrixCFD'); 
save(fullfile(currentSubDir,'blueMatrixCFD.mat'), 'blueMatrixCFD');
save(fullfile(currentSubDir, 'CFDImage.mat'), 'CFDImage');
    %Load full camera image and run the compare images function
    %load exampleImage.mat;
    %[CFDImageOut, cameraImageLeftOut, cameraImageRightOut, commonBaseHeight] = createCompareImages(imC, CFDImage, 'base');
    
%Load full camera image and run the compare images function
%load exampleImage.mat;
%[CFDImageOut, cameraImageLeftOut, cameraImageRightOut, commonBaseHeight] = createCompareImages(imC, CFDImage, 'base');

%Save images. In the case of 12 bit sensor, to show the images properly,
%multiplu by 16 - the image is written in 16 bits, if you don't multiply,
%it is going to be a very dark image
%imwrite(uint16(CFDImageOut*16), 'CFDImage16.tif');
%imwrite(uint16(cameraImageLeftOut*16), 'CameraLeftImage1.tif');
%imwrite(uint16(cameraImageRightOut*16), 'CameraRightImage1.tif');
