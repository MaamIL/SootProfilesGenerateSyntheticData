%This is the main file of the picture reconstruction code. It builds a
%color image from CFD flame calculation. See description for details.

%Input variables:
%
%TCFD:                   Temperature matrix from the CFD calculations. The size is MxN and is determined by the CFD code
%fvCFD:                  Soot volume fraction matrix from the CFD calculations. The size is MxN and is determined by the CFD code
%rCFD:                   The r axis from the CFD calculations. The size is Nx1
%zCFD:                   The z axis from the CFD calculations. The size is Mx1
%cameraSpectralResponse: The spectral response of the camera. It contains 4 columns. The first is the wavelength[nm], the second is the red sensor response at the given wavelength, the third is the green sensor response and 
%                        the fourth - the blue sensor response
%pixelSize:              Pixel size for the given optical size, mm. 
%IntensityCalibration:   Calbiration of intensity per pixel value. Vector of a size of [3X1] - for red, green and blue channels accordingly.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
%Output variables:
%
%redMatrix:     Matrix of the pixel values for the colour red. Matrix of size Mp x Np
%greenMatrix:   Matrix of the pixel values for the colour green. Matrix of size Mp x Np
%blueMatrix:	Matrix of the pixel values for the colour blue. Matrix of size Mp x Np
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%List of variables:

% blueLine:     A vector of size n of blue pixel values for the particular flame height. n depends on the flame height
% fvPixelated:	Soot volume fraction [ppm] interpolated for pixelSize. Matrix of size Mp x Np
% greenLine:	A vector of size n of green pixel values for the particular flame height. n depends on the flame height
% indLast:      The index beyond which the soot volume fraction is zero (defines the radius at give height)
% indLocalMax:  Assistant variable - max soot volume fraction at that height.
% indZeros:     Assistant variable - the indexes of zeros for certain height.
% maxfv:        Maximum total soot volume fraction
% n:            Length of the vectors at the working height.
% pixelSize:	Size of the pixel [mm]
% redLine:      A vector of size n of red pixel values for the particular flame height. n depends on the flame height
% rPicture:     Vector for the r direction in pixelSize steps. The size is 1xNp (determined by pixelSize)
% TPixelated:	Temperature [K] interpolated for pixelSize. Matrix of size Mp x Np 
% zPicture:     Vector for the z direction in pixelSize steps. The size is 1xMp (determined by pixelSize)

function [redMatrix, greenMatrix, blueMatrix] = buildPicture(TCFD, fvCFD, rCFD, zCFD, cameraSpectralResponse, pixelSize, IntensityCalibration)
tic
%Create z to match pixel size, and interpolate the data accordingly. Firstly interpolation in z direction is done; then intperpolation in the r direction is done. In the end the fVPixelated and TPixelated are matrixes 
%interpoalated by the pixel size

%Create the grid for the image with the pixel size
rPicture = rCFD(1):pixelSize:rCFD(end);
zPicture = zCFD(1):pixelSize:zCFD(end);

%Interpolate the data to match the new grid 
fvPixelated = spline(zCFD, fvCFD', zPicture)';
TPixelated = spline(zCFD, TCFD', zPicture)';
fvPixelated = spline(rCFD,fvPixelated,rPicture);
TPixelated = spline(rCFD,TPixelated,rPicture);
maxfv = max(max(fvPixelated));

%Matrix allocation
redMatrix = zeros(length(zPicture), length(rPicture));
greenMatrix = zeros(length(zPicture), length(rPicture));
blueMatrix = zeros(length(zPicture), length(rPicture));

% Addit pixel values one flame height at a time
for i = 1:length(zPicture)            
    if max(fvPixelated(i,:)) < 1e-3*maxfv %Skip the line if there is no soot in it.
        continue
    end

    %Find the index where non-zero line ends.
    % indZeros = find(abs(fvPixelated(i,:)) < 1e-3*maxfv) - 1;
    indZeros = find(abs(fvPixelated(i,:)) <= 0.1) - 1;
    [~,indLocalMax] = max(fvPixelated(i,:));
    indIndLast = find(indZeros > indLocalMax);
    indLast = indZeros(indIndLast(1));  

    [redLine,greenLine,blueLine] = lineRGB(rPicture(1:indLast), fvPixelated(i,1:indLast), TPixelated(i,1:indLast), cameraSpectralResponse, pixelSize, IntensityCalibration); %Get red, green and blue values of the row.
    n = length(redLine);
    
    %Update the pixel values in the picture matrix. 
    redMatrix(i,1:n) = redLine;
    greenMatrix(i,1:n) = greenLine;
    blueMatrix(i,1:n) = blueLine;
    
    if mod(i,100) == 0 %Displays progress. 
        sprintf('Line %d out of %d',i,length(zPicture))        
    end
end