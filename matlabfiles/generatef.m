function fOut = generatef(j)
% clear

rng('shuffle');
load fPolynoms
% j = 4;

rng('shuffle');
fMax = 7.18;
% LMax = 70;

L = round(normrnd(muInd3f(j),stdInd3f(j))); %L is the total length of the vector. It is not the final number. 
ind1 = round(normrnd(muInd1f(j),stdInd1f(j))); %ind1 is the first polinomial lenghh
ind2 = L+1; %ind2 is the second polinomial length
while (ind2 > L) || (ind2 < ind1)
    ind2 = round(normrnd(muInd2f(j),stdInd2f(j)));
end

%First part
flag = 0;
while flag == 0
    flag = 1;
    a11 = normrnd(mup11f(j), stdp11f(j));
    a12 = normrnd(mup12f(j), stdp12f(j));
    a13 = normrnd(mup13f(j), stdp13f(j));
    a14 = normrnd(mup14f(j), stdp14f(j));    

    x1 = 1:ind1;
    y1 = polyval([a11,a12,a13,a14], x1);    
    
end

flag = 0;
while flag == 0
    flag = 1;
    a21 = normrnd(mup21f(j), stdp21f(j));
    a22 = normrnd(mup22f(j), stdp22f(j));
    a23 = normrnd(mup23f(j), stdp23f(j));
    a24 = normrnd(mup24f(j), stdp24f(j));

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
    a31 = normrnd(mup31f(j), stdp31f(j));
    a32 = normrnd(mup32f(j), stdp32f(j));
    a33 = normrnd(mup33f(j), stdp33f(j));
    a34 = normrnd(mup34f(j), stdp34f(j));

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

    % flagIn = 0;
    if any(3*a31*x3.^2+2*a32*x3+a33 > 0)
        % flagIn = 1;
        flag = 0;
        % lala = 3*a31*x3.^2+2*a32*x3+a33;
        % indZero = find(lala > 0);
        % reducedL = length(indZero);
        % L = L-reducedL;        
        % y3(indZero) = [];
    end
end

flag = 0;
y = [y1(1:end), y2(2:end), y3(2:end)];
indZero = find(y<0);
y(indZero) = 0;
while flag == 0
    % if y(end) < 0.1;
    %     y(end) = 0;
    %     flag = 1;
    %     continue
    % end
    L = L+1;
    y(L) = interp1(1:L-1,y,L,"linear","extrap");
    if y(L) <= 0
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

fOut = smooth(y)*fMax;
lala = 1;
% fOut = [y1(1:end), y2(2:end)]*fMax;