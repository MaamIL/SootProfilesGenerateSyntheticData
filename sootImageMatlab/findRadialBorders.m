%For a given total signal (line), the function gives the indexes between
%which the important signal lies;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Input variables:
%signalIn - a double vector of all the pixels at a certain flame height.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Output variables
%leftIndexOut: the index in signalIn that indicates the flame left border.
%              Scalar
%rightIndexOut: the index in signalIn that indicates the flame right
%               border. Scalar

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Variable list:
%iiLeft, iiRight: dummy variables. Scalars
%localMinMaxIndexs: a vector of indexes of signalIn that indicates an
%                   extreme point

function [leftIndexOut, rightIndexOut] = findRadialBorders(signalIn)

localMinMaxIndexes = sort([find(islocalmin(signalIn)), find(islocalmax(signalIn))]); %Indexes of the local extreme points

[~,iiLeft] = max(diff(signalIn(localMinMaxIndexes))); %Find the largest increase between extreme points
[~,iiRight] = min(diff(signalIn(localMinMaxIndexes))); %Find the largest drop between extreme points

leftIndexOut = localMinMaxIndexes(iiLeft);
rightIndexOut = localMinMaxIndexes(iiRight+1);