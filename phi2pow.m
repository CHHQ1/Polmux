function pwr=phi2pow(phi,L,alpha,gam,G,nspan)

%PHI2POW Convert nonlinear phase into power.
%   PWR=PHI2POW(PHI,L,ALPHA,GAM,G,NSPAN) yields the transmitted power 
%   PWR [mW] corresponding to a cumulated nonlinear phase into the overall 
%   optical link equal to PHI [rad]. PHI is the self-phase modulation (SPM)
%   rotation induced by the link over a constant signal of power PWR.
%
%   L is a vector of size equal to the number of nonlinear fibers in the 
%   link and contains the fiber lengths in [m]. ALPHA are the fibers 
%   attenuation [dB/km], GAM are the fibers nonlinear coefficients, usually 
%   called gamma [1/W/m].
%   G is the net gain [dB] from fiber to fiber (see the example).
%
%   If L,ALPHA,GAM,G are of length 1, the same value is used for a total 
%   of NSPAN spans.
%   
%
%   E.g. Two-fiber periodic link of N spans. One of the NSPAN periods is:
%
%   ampli0     fiber 1     ampli1        fiber 2     ampli2=ampli0
%               ___                       ___    
%   |\         /   \       |\            /   \       |\
%   | \       |     |      | \          |     |      | \
%   |  \       \   /       |  \          \   /       |  \ 
%   |   >------------------|   >---------------------|   >--- ...
%   |  / 0               L1|  /                 L1+L2|  /
%   | /                    | /                       | /
%   |/                     |/                        |/ 
%   gain  attenuation a1   gain    attenuation a2    gain   
%   G0    nl-index gam1    G1      nl-index gam2     G2=G0
%
%
%   Call the function with:
%   L = [L1,L2], ALPHA = [a1,a2], GAM = [gam1,gam2], 
%   G=[G0,G1]
%
%   Note 1: If the laser is directly connected to the link, G0=0 dB
%   Note 2: transparent link of N equal spans -> L = L1, ALPHA=a1, 
%         G=0 and NSPAN = N.
%
%   The function returns PWR [mW] that entering the amplifier ampli0 gives
%   the cumulated nonlinear phase PHI.
%
%   See also POW2PHI
%
%   Author: Paolo Serena, 2009
%   University of Parma, Italy

%    This file is part of Optilux, the optical simulator toolbox.
%    Copyright (C) 2009  Paolo Serena, <serena@tlc.unipr.it>
%			 
%    Optilux is free software; you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation; either version 3 of the License, or
%    (at your option) any later version.
%
%    Optilux is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.


global GSTATE   % GSTATE is a structure whose fields are defined in reset_all.m

Ll = length(L);
La = length(alpha);
Lgam = length(gam);
LG = length(G);

if (abs(Ll-La)+abs(Ll-Lgam)+abs(Lgam-LG)) ~= 0
    error('All fiber parameters must be of the same length');
end

alphalin = (log(10)*1e-4)*alpha;             % [m^-1]
indnz = find(alphalin);             % non-zero indexes
indz = find(alphalin == 0);         % zero indexes
Leff(indnz) = (1-exp(-alphalin(indnz).*L(indnz)))./alphalin(indnz);
Leff(indz) = L(indz);   % effective length [m]
loss = -alpha.*L*1e-3;       % fiber loss [dB]
netgain = [0,loss(1:La-1)]+G; % netgain(k)= net gain [dB] of (k-1)-th fiber + k-th ampli
cumgain = 10.^(cumsum(netgain)*0.1);    % cumulative gain: cumgain(k)*pwragv is the power input to the k-th fiber

pwr = phi/sum(Leff.*gam.*cumgain*nspan)*1e3;  % [mW]

if GSTATE.PRINT

    %%%% PRINT summary

    outfile = [GSTATE.DIR,'/simul_out'];

    fid = fopen(outfile,'a');

    fprintf(fid,'========================================\n');
    fprintf(fid,'===            phi2pow               ===\n');
    fprintf(fid,'========================================\n\n');
    fprintf(fid,'Nonlinear Phase converted into power. Optical system used:\n\n');
    fprintf(fid,'Length [m]  Alpha [dB/km]  Gamma [1/mW/km]  Gain [dB]\n\n');
    for k=1:Ll
	fprintf(fid,'%-12.6g%-15.2f%-17.2e%-15.2f\n',L(k),alpha(k),gam(k),G(k));
    end
    if (Ll+La+Lgam+LG) == 4
	fprintf(fid,'\nNL Phase cumulated into %d equal spans\n',nspan);
    end
    fprintf(fid,'\nNL Phase: %.3f*pi [rad] -> Tx power: %.4g  [mW]\n',...
            phi/pi,pwr);
    fprintf(fid,'\n****************************************\n\n');

    fclose(fid);
    
end  % if GSTATE.PRINT 
