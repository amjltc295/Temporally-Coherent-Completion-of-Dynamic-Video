%compare(mat,ext)
%----------------
%
%Compare the performance of elementary external versus built-in functions.
%A sample benchmark is found in "Pentium4m2GHz.mat".
%
%Input:
% mat    Benchmark of built-in functions
% ext    Benchmark of the same external functions
%

% Optimized class functions for MATLAB on x86 computers.
% Copyright © Marcel Leutenegger, 2003-2007, École Polytechnique Fédérale de Lausanne (EPFL),
% Laboratoire d'Optique Biomédicale (LOB), BM - Station 17, 1015 Lausanne, Switzerland.
%
%     This library is free software; you can redistribute it and/or modify it under
%     the terms of the GNU Lesser General Public License as published by the Free
%     Software Foundation; version 2.1 of the License.
%
%     This library is distributed in the hope that it will be useful, but WITHOUT ANY
%     WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
%     PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
%
%     You should have received a copy of the GNU Lesser General Public License along
%     with this library; if not, write to the Free Software Foundation, Inc.,
%     51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

function compare(mat,ext)
r=(mat.time-repmat(mat.call,size(mat.name)))./(ext.time-repmat(ext.call,size(ext.name)));
rmin=min(r,[],2);
rmax=max(r,[],2);
%
% Highest improvement is placed top
%
[rmean,r]=sort(mean(r,2));
rmin=rmin(r);
rmax=rmax(r);
%
% Reorder function names
%
for k=1:length(mat.name)
   name{k}=mat.name{r(k)};
   if ~isequal(name{k},ext.name{r(k)})
      error('Different built-in and external functions benchmarked.');
   end
end
%
% Draw the chart
%
r=ceil(max(rmax));
figure('Name','Performance of elementary functions','NumberTitle','off');
axes('Box','off','Color','none','NextPlot','add','XGrid','on','XLim',[0 r],'XTick',1:2:r,'YLim',[0.5 0.5+length(mat.name)],'YTick',1:28,'YTickLabel',name);
title('Benchmark of elementary functions for vectors with 2^{0:12} numbers');
xlabel('Performance of external over built-in functions');
barh(rmax,0.6,'g');
barh(rmean,0.6,'b');
barh(rmin,0.6,'r');
legend('max','mean','min',4);
