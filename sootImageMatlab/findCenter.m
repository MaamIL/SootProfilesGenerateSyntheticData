%This function finds the centre of a supposedly symmetric signal. The
%principle behind the operation is to find the most symmetric point. This
%is done by finding the point at which the integral of the points on the right
%of it and on the left of it is as similar as possible.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Input variables
%signalIn: signal vector. The signal has to be stripped of the non-relevant
%          parts (i.e. - outside of the flame should be trimmed).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Output variables
%centerIndOut: the index of signalIn that serves as a center. 

function centerIndOut = findCenter(signalIn)

signalSum = cumtrapz(signalIn); %Cumulative integral of the signal
halfInd = find(signalSum > 0.5*signalSum(end),1,'first'); %find where the sum is a bit more than half of the maximum sum

%This finds which point is closer to the exact half of the total sum. It
%can be either the first point after the half mark is crossed, or the
%previous one. 
if abs(signalSum(halfInd) - 0.5*signalSum(end)) < abs(signalSum(halfInd-1) - 0.5*signalSum(end))
    centerIndOut = halfInd;
else
    centerIndOut = halfInd - 1;
end

