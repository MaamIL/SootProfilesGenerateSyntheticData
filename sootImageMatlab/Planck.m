function B = Planck(lambda,T)

h = 6.62607004e-34; %Plank constant
c = 299792458; %speed of light
kb = 1.38064852e-23; %Boltzmann constant

B = (2*h*c^2)./(lambda.^5.*(exp(h.*c./(lambda.*kb.*T))-1));