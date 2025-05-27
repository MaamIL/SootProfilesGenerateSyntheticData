%This function builds RGB values for a picture reconstruction at a certain
%flame height. 
% 
%%%%%%%%%%%%%%%%%%%%%%%%Inputs%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%rIn [mm]               The radius vector. The last member of the vector is the flame radius
%fIn [ppm]              The soot volume fraction f(r)
%TIn [K]                The temperature T(r)
%LUX                    The spectral response of the camera. The first row is lambda in mm, the second row is the red spectral response, the third row is the green spectral response, and the fourth 
%                       row is the blue spectral response.
%pixelSize [mm]         The size of the pixel in the picture
%IntensityCalibration   Calbiration of intensity per pixel value. Vector of a size of [3X1] - for red, green and blue channels accordingly.

%%%%%%%%%%%%%%%%%%%%%%%%Outputs%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%rPixelValue    A vector of length(rIn) that contains pixel values for the colour red. The values are in uint16.
%gPixelValue    A vector of length(rIn) that contains pixel values for the colour green. The values are in uint16.
%bPixelValue    A vector of length(rIn) that contains pixel values for the colour blue. The values are in uint16.

%%%%%%%%%%%%%%%%%%%%%%%%List of variables%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% abs_exponent      The extinction part of the line of sight integral
% blueCalibration	Calibration of the radiance to blue pixel value. The actual integrated radiance needs to be divided by this number
% blueI             I after the blue filter was applied to it
% blueW             The radiance that the blue pixels "see". Size is 1 x length(rIn). Obtained by integrating blueI over the wavelengths.
% greenCalibration	Calibration of the radiance to green pixel value. The actual integrated radiance needs to be divided by this number
% eps               The value inside the integral (see paper), including extinction. The size is length(LUX) x length(y) - it give the value of the integral for each wavelength on each point of 
%                   the line of sight
% fy                Soot volume fraction along line of sight.
% greenI            I after the green filter was applied to it
% greenW            The radiance that the green pixels "see". Size is 1 x length(rIn). Obtained by integrating greenI over the wavelengths.
% I                 Local spectral radiance matrix. Each row represents the radiance for the matching wavelength in lambda. Size is length(lambda) x length(rIn)
% lambda            Wavelength vector [nm]. 
% M                 Length of the spectral response vector
% n                 Length of the radius vector
% R                 The radius of the flame
% redCalibration	Calibration of the radiance to red pixel value. The actual integrated radiance needs to be divided by this number
% redI              I after the red filter was applied to it
% redW              The radiance that the red pixels "see". Size is 1 x length(rIn). Obtained by integrating redI over the wavelengths. 
% ry                Values of the radius along the line of sight
% Ty                Values of the temperature along the line of sight
% y                 Line of sight
% y0                The value of y at the radius for given x
% yint              Spectral integration along the line of sight. 


function [rPixelValue,gPixelValue,bPixelValue] = lineRGB(rIn, fIn, TIn, LUX, pixelSize, IntensityCalibration)

rIn = rIn*1e-3; %Conversion to m;
fIn = fIn*1e-6; %Conversion to fractions;
pixelSize = pixelSize*1e-3; %Conversion to m;
EofM = 0.26;

redCalibration = IntensityCalibration(1); %(W/m^2/str) / pixelValue
greenCalibration = IntensityCalibration(2); %(W/m^2/str) / pixelValue
blueCalibration = IntensityCalibration(3); %(W/m^2/str) / pixelValue

lambda = LUX(:,1)*1e-9;  %Conversion to m
M = length(lambda);

%The spectral radiance integrated on the line of site
for i = 1:length(rIn) - 1     
    R = rIn(end);
    y0 = sqrt(R^2-rIn(i)^2);
    y = -y0:pixelSize:y0; %the vector along which the integration is performed
    ry = sqrt(rIn(i)^2 + y.^2);
    fy = spline(rIn,fIn,ry);
    Ty = spline(rIn,TIn,ry);

    eps = zeros(M,length(fy));
    for j = 1:length(fy)
        kabs(1:M,j) = 6.*pi.*EofM.*fy(j)./lambda;         
        local_eps(1:M,j) = 6.*pi.*EofM.*Planck(lambda,Ty(j)).*fy(j)./lambda;        
    end
    
    abs_exponent = exp(-(trapz(y,kabs,2) - cumtrapz(y,kabs,2)));     
    eps = local_eps.*abs_exponent;

    yint = trapz(y,eps,2);
    
    redW(i) = trapz(lambda,yint.*LUX(:,2));
    greenW(i) = trapz(lambda,yint.*LUX(:,3));
    blueW(i) = trapz(lambda,yint.*LUX(:,4));

    clear kabs local_eps
end

n = length(rIn);
redW(n) = 0;
greenW(n) = 0;
blueW(n) = 0;

%Conversion of the intensities to pixel values
rPixelValue = (redW/redCalibration);
gPixelValue = (greenW/greenCalibration);
bPixelValue = (blueW/blueCalibration);