%This function creates the images for comparison - image created from CFD
%results, and right and left parts of camera image

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Input variables:
%cameraImageIn: the demosaiced image from the camera (3D Matrix). Make sure it's the uint16 image. Has to be flame tip up
%
%CFDImageIn: the image that was created from the CFD results. Also 3D matrix. Has to be flame tip up. Should be double
%
%origin: can be either 'maxPixel' or 'base'. maxPixel is if we want to have a common origin at the height of maximim pixel value, base if we want it to be at the flame base
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Output variables:
%3D matrixes of the same size so it is possible to compare them. The matrixes are double and not int, because it is easier this way. To get the image you have to convert them to uint16 and multiply 
%by 16 (images are 12 bit, uint16 is 16 bit).
%
%commonBaseHeight: The height (in pixels) of the common origin point. For 'maxPixel' it is going to be what is calculated, for "base" it is going to be the longest flame height.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Variables
%
%cameraImageLeft: the left part of the flame, untrimmed.
%
%cameraImageRight: the right part of the flame, untrimmed.
%
%%cameraLowerPart: The length of the real flame between the height of the maximum intensity and the bottom
%
%cameraUpperPart: The length of the real flame between the height of the maximum intensity and the tip
%
%CFDLowerPart: The length of the CFD flame between the height of the maximum intensity and the bottom
%
%CFDUpperPart: The length of the CFD flame between the height of the maximum intensity and the tip
%
%downlength: vertical distance from the point of maximum soot to the bottom of the flame
%
%flameBottom: The vertical location of the real flame base (in pixels)
%
%flameBottomCFD: The vertical location of the CFD flame base (in pixels)
%
%flameBottomCenter: The horizontal location of the center of the bottom of the real flame
%
%flameBottomLeft: The horizontal location of the left side of the bottom of the real flame
%
%flameBottomRight: The horizontal location of the right side of the bottom of the real flame
%
%flameTop: The vertical location of the real flame tip (in pixels)
%
%flameTopCFD: The vertical location of the CFD flame tip (in pixels)
%
%flameTopCenter: The horizontal location of the center of the top of the real flame
%
%flameTopLeft: The horizontal location of the left side of the top of the real flame
%
%flameTopRight: The horizontal location of the right side of the top of the real flame
%
%flameWidthCFD: The half width of the CFD flame
%
%flameWidthLeft: The width of the left part of the real flame
%
%flameWidthRight: The width of the right part of the real flame
%
%heightOutputImage: the total height, in pixel, of the final images.
%
%indStam: dummy variable
%
%maxPixelHeight: the height of maximum pixel value for real flame
%
%maxPixelHeightCFD: the height of maximum pixel value for CFD flame
%
%redCameraImageIn: The red part of the image of the real flame (double)
%
%redMatrix: The red part of the CFD image
%
%redWorkImage: The red part of the work image of the real flame. If the image wasn't rotated it will the same as redCameraImageIn.
%
%startHeight: in the case of common origin being the point of max intnesity the image is built from top to down in 2 steps. startHeight is the height at which the second part starts.
%
%theta: image rotation angle, degrees
%
%uplengh: vertical distance from the point of maximum soot to the top of the flame
%
%widthOutputImage: the width of output image
%
%workImage: the camera image that we work with (it might be after rotation)
%
%xx: Dummy variable
%
%yy: Dummy variable


function [CFDImageOut, cameraImageLeftOut, cameraImageRightOut, commonBaseHeight] = createCompareImages(cameraImageIn, CFDImageIn, origin)

if nargin < 3
    origin = 'maxPixel';
end

if not(strcmpi(origin, 'maxPixel')) && not(strcmpi(origin, 'base'))
    error ('Invalid origin');
end

%%Step 1 - Make sure the camera image is vertical
%Step 1.1 - Determine the vertical coordinates of the tip and the base
redCameraImageIn = double(cameraImageIn(:,:,1));
[flameTop, flameBottom] = findFlameRange(redCameraImageIn);

%Step 1.2 and 1.3 - Determine the horizontal coordinates of the tip and the base
[flameTopLeft, flameTopRight] = findRadialBorders(redCameraImageIn(flameTop,:));
flameTopCenter = findCenter(redCameraImageIn(flameTop,flameTopLeft:flameTopRight)) + flameTopLeft - 1;

[flameBottomLeft, flameBottomRight] = findRadialBorders(redCameraImageIn(flameBottom,:));
flameBottomCenter = findCenter(redCameraImageIn(flameBottom,flameBottomLeft:flameBottomRight))+ flameBottomLeft - 1;

%Step 1.4 - Determine the rotation angle 
theta = atand((flameTopCenter-flameBottomCenter)/(flameBottom-flameTop));

%Step 1.5 - Rotate the image
if abs(theta) > 1
    workImage = imrotate(cameraImageIn,theta);
else
    workImage = cameraImageIn;
end

%%Step 2 - Divide the camera image to left and right
redWorkImage = double(workImage(:,:,1));
if abs(theta) > 1 %If the image was rotated, the coordinates of flame borders need to be recaclulated. 
    [flameTop, flameBottom] = findFlameRange(redWorkImage);
    [flameTopLeft, flameTopRight] = findRadialBorders(redWorkImage(flameTop,:));
    flameTopCenter = findCenter(redWorkImage(flameTop,flameTopLeft:flameTopRight));
end
cameraImageLeft = fliplr(workImage(:,1:flameTopCenter,:));
cameraImageRight = workImage(:,flameTopCenter:end,:);

%%Step 3 - Determine the common flame length
%Step 3.1
redMatrix = CFDImageIn(:,:,1);
[xx, yy] = find(redMatrix > 0.05*max(max(redMatrix)));
flameTopCFD = min(xx);
flameBottomCFD = max(xx);

if strcmpi(origin, 'maxPixel') %Step 3.2 - if origin is at maximum pixel
    %Step 3.2.1
    [maxPixelHeightCFD,~] = find(CFDImageIn(:,:,1) == max(max(CFDImageIn(:,:,1)))); 
    [maxPixelHeight,~] = find(redWorkImage == max(max(redWorkImage)));          
    
    %Step 3.2.2
    uplength = max([abs(flameTopCFD - maxPixelHeightCFD), abs(flameTop - maxPixelHeight(1))]);
    downlength = max([abs(flameBottomCFD - maxPixelHeightCFD), abs(flameBottom - maxPixelHeight(1))]);    
    heightOutputImage = uplength+downlength+1;
else
    %Step 3.3
    heightOutputImage = max([abs(flameTop-flameBottom), abs(flameTopCFD-flameBottomCFD)])+1;
end

%%Step 4 - Determine the common half width of the flame
flameWidthCFD = max(yy);

if abs(theta) > 1
    [flameBottomLeft, flameBottomRight] = findRadialBorders(redWorkImage(flameBottom,:));    
end
flameWidthLeft = abs(flameTopCenter - flameBottomLeft) + 1;
flameWidthRight = abs(flameTopCenter - flameBottomRight) + 1;

widthOutputImage = max([flameWidthCFD, flameWidthLeft, flameWidthRight]);

%%Step 5 - Create the output images
CFDImageOut = zeros(heightOutputImage, widthOutputImage, 3);
cameraImageLeftOut = zeros(heightOutputImage, widthOutputImage, 3);
cameraImageRightOut = zeros(heightOutputImage, widthOutputImage, 3);

if strcmpi(origin, 'maxPixel')
    %Fill the upper part of the images
    CFDUpperPart = maxPixelHeightCFD - flameTopCFD;
    cameraUpperPart = maxPixelHeight(1) - flameTop;
    if CFDUpperPart > cameraUpperPart
        CFDImageOut(1:CFDUpperPart+1,:,:) = CFDImageIn(flameTopCFD:maxPixelHeightCFD,1:widthOutputImage,:);
        cameraImageRightOut(CFDUpperPart + 1 - cameraUpperPart:CFDUpperPart + 1,:,:) = cameraImageRight(flameTop:maxPixelHeight(1),1:widthOutputImage,:);
        cameraImageLeftOut(CFDUpperPart + 1 - cameraUpperPart:CFDUpperPart + 1,:,:) = cameraImageLeft(flameTop:maxPixelHeight(1),1:widthOutputImage,:);
        commonBaseHeight = CFDUpperPart+1;
    else
        cameraImageRightOut(1:cameraUpperPart+1,:,:) = cameraImageRight(flameTop:maxPixelHeight(1),1:widthOutputImage,:);
        cameraImageLeftOut(1:cameraUpperPart+1,:,:) = cameraImageLeft(flameTop:maxPixelHeight(1),1:widthOutputImage,:);
        CFDImageOut(cameraUpperPart + 1 - CFDUpperPart:cameraUpperPart + 1,:,:) = CFDImageIn(flameTopCFD:maxPixelHeightCFD,1:widthOutputImage,:);
        commonBaseHeight = cameraUpperPart+1;
    end
    
    
    %Fill the lower part of the images
    [xx,~] = find(CFDImageOut == 0);
    indStam = find(xx > CFDUpperPart+1, 1,'first');
    startHeight = xx(indStam);
    CFDLowerPart = flameBottomCFD - maxPixelHeightCFD;
    CFDImageOut(startHeight:startHeight+CFDLowerPart,:,:) = CFDImageIn(maxPixelHeightCFD:flameBottomCFD,1:widthOutputImage,:);
    
    cameraLowerPart = flameBottom - maxPixelHeight(1);
    cameraImageRightOut(startHeight-1:startHeight+cameraLowerPart-1,:,:) = cameraImageRight(maxPixelHeight(1):flameBottom, 1:widthOutputImage,:);
    cameraImageLeftOut(startHeight-1:startHeight+cameraLowerPart-1,:,:) = cameraImageLeft(maxPixelHeight(1):flameBottom, 1:widthOutputImage,:);    
else
    if abs(flameTop-flameBottom) > abs(flameTopCFD-flameBottomCFD)
        cameraImageRightOut = double(cameraImageRight(flameTop:flameBottom,1:widthOutputImage,:));
        cameraImageLeftOut = double(cameraImageLeft(flameTop:flameBottom,1:widthOutputImage,:));
        startHeight = abs(flameTop-flameBottom) - abs(flameTopCFD-flameBottomCFD);
        CFDImageOut(startHeight+1:heightOutputImage,:,:) = CFDImageIn(flameTopCFD:flameBottomCFD,1:widthOutputImage,:);
    else
        CFDImageOut = CFDImageIn(flameTopCFD:flameBottomCFD,1:widthOutputImage,:);
        startHeight = abs(flameTopCFD-flameBottomCFD)- abs(flameTop-flameBottom);
        cameraImageRightOut(startHeight+1:heightOutputImage,:,:) = double(cameraImageRight(flameTop:flameBottom,1:widthOutputImage,:));
        cameraImageLeftOut(startHeight+1:heightOutputImage,:,:) = double(cameraImageLeft(flameTop:flameBottom,1:widthOutputImage,:));
    end
    commonBaseHeight = length(CFDImageOut);
end

lala = 1;