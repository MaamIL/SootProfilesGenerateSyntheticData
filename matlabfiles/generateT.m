function TOut = generateT(j)
% clear
rng('shuffle');
TMax = 2118;
% LMax = 70;
load TPolynoms
% j = 4;

L = round(normrnd(muInd3T(j),stdInd3T(j)));
ind1 = round(normrnd(muInd1T(j),stdInd1T(j)));
ind2 = L+1;
while (ind2 > L) || (ind2 < ind1)
    ind2 = round(normrnd(muInd2T(j),stdInd2T(j)));
end

%First part
flag = 0;
while flag == 0
    flag = 1;
    a11 = normrnd(mup11T(j), stdp11T(j));
    a12 = normrnd(mup12T(j), stdp12T(j));
    a13 = normrnd(mup13T(j), stdp13T(j));
    a14 = normrnd(mup14T(j), stdp14T(j));    

    x1 = 1:ind1;
    y1 = polyval([a11,a12,a13,a14], x1);   
    
end

flag = 0;
while flag == 0
    flag = 1;
    a21 = normrnd(mup21T(j), stdp21T(j));
    a22 = normrnd(mup22T(j), stdp22T(j));
    a23 = normrnd(mup23T(j), stdp23T(j));
    a24 = normrnd(mup24T(j), stdp24T(j));

    x2 = 1:(ind2-ind1+1);
    y2 = polyval([a21,a22,a23,a24], x2);

    if any(y2 < 0)
        flag = 0;
    end

    if any(6*a21*x2 + 2*a22 > 0)
        flag = 0;
    end    

    if max(y2) == y2(end)
        flag = 0;
    end

    d2 = y2(1) - y1(end);
    y2 = y2 - d2;    
end

flag = 0;
while flag == 0
    flag = 1;
    a31 = normrnd(mup31T(j), stdp31T(j));
    a32 = normrnd(mup32T(j), stdp32T(j));
    a33 = normrnd(mup33T(j), stdp33T(j));
    a34 = normrnd(mup34T(j), stdp34T(j));

    x3 = 1:(L-ind2+1);
    y3 = polyval([a31,a32,a33,a34],x3);

    % if any(6*a33*x1 + 2*a32 < 0)
    %     flag = 0;
    % end    

    d3 = y3(1) - y2(end);
    y3 = y3 - d3;

    if any(y3 < 0)
        indZero = find(y3 < 0);
        y3(indZero) = 0;
    end

    if any(diff(y3) > 0)
        lala = diff(y3);
        indZero = find(lala > 0)+1;
        y3(indZero) = 0;
    end
end

flag = 0;
y = [y1(1:end), y2(2:end), y3(2:end)];
indZero = find(y<0);
y(indZero) = 0;
while flag == 0
    if y(end) < 0.1;
        y(end) = 0;
        flag = 1;
        continue
    end
    L = L+1;
    y(L) = interp1(1:L-1,y,L,"linear","extrap");
    if y(L) < 0
        y(L) = 0;
        flag = 1;
    end
end

% a23 = normrnd(-32.9488360430424, 14.7113272590538);
% a22 = normrnd(48.8510114941831, 23.6185723186173);
% a21 = normrnd(-21.8540465341532, 13.3274975245972);
% a20 = normrnd(3.22904275872436, 2.70564103883095);
% 
% a33 = normrnd(-7.56652629059481, 23.2249517273368);
% a32 = normrnd(30.0042453210982, 63.6504902618318);
% a31 = normrnd(-37.1915601476818, 58.1885376914996);
% a30 = normrnd(14.7580359193041, 17.8056585819853);




% x2 = x1(end):dx:ind2;
% y2 = polyval([a23,a22,a21,a20], x2);
% d2 = y2(1) - y1(end);
% y2 = y2 - d2;
% 
% x3 = x2(end):dx:1;
% y3 = polyval([a33,a32,a31,a30], x3);
% d3 = y3(1) - y2(end);
% y3 = y3 - d3;
% 
% fNonZeroLength = length(y1) + length(y2) + length(y3) - 2;
% 
% fOut(1:fNonZeroLength) = [y1(1:end), y2(2:end), y3(2:end)]*fMax;
% 
% indNeg = find(fOut < 0);
% fOut(indNeg) = 0;
% fOut = y1*fMax;

% fOut = y*fMax;
lala = 1;
TOut = y*(TMax-300)+300;