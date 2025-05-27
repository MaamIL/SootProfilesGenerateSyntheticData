%This function assumes that the flame is horizontal and finds its range.
%The function runs integrals on each flame height. The flame range is where
%the integrals are higher than 5% of the maximum.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Input:
%imageIn - a picture matrix, uint16; I would usually use the red one - it
%is the less noisy one

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Output:
%flameRangeOut. Contains two numbers - starting and ending pixel. The
%pixels are not in order - we don't know which pixel is the base and which
%pixel is the tip.

function [flameTop, flameBottom] = findFlameRange(imageIn)
intPixels = trapz(double(imageIn),2); %Runs an integral over pixel values along the slices. For imageIn MxN we get a 1xN vector

flameTop = find(intPixels > 0.05*max(intPixels), 1, 'first');
flameBottom = find(intPixels > 0.05*max(intPixels), 1, 'last');