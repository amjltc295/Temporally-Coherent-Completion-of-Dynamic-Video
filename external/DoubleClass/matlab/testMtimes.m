%testMtimes(typ,frq)
%-------------------
%
%Test the matrix multiplication. Print typical error and benchmark.
%
%Input:
% typ    Conversion function handle for test data type
% frq    Clock speed of the processor {2GHz}
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

function benchMtimes(typ,frq)
if nargin < 1 | isempty(typ)
   typ=@double;
end
if nargin < 2 | isempty(frq)
   frq=2e3;
else
   frq=frq(1)/1e6;
end
%
% Print header and test summaries
%
clc;
fprintf('\n           Test matrix multiplication of class "%s"',func2str(typ));
fprintf('\n___________________________________________________________________\n');
fprintf('\n\t\t\tsr = s is real\t\t\tsz = s is complex');
fprintf('\n\t\t\ttr = t is real\t\t\ttz = t is complex\n');
fprintf('\nTesting "mtimes":\n%24s%26s%15s\n','dimensions','performance','error');
for m=1:16
   for k=[1 2 5]
      for n=[1 2 5]
         run(typ,frq,m,k,n);
      end
   end
end
for m=20:59:256
   for k=16:32:128
      for n=24:64:256
         run(typ,frq,m,k,n);
      end
   end
end
run(typ,frq,160,640,200);
run(typ,frq,500,800,400);


function run(typ,frq,m,k,n)
sr=feval(typ,randn(m,k));
tr=feval(typ,randn(k,n));
sz=complex(sr,randn(m,k));
tz=complex(tr,randn(k,n));
ops=frq*m*n*([2;4;4;6]*k - 1);
fprintf('       [%3d x %3d]*[%3d x %3d]',m,k,k,n);
clk=zeros(4,1);
timer;
rr=sr*tr;
clk(1)=timer;
rz=sr*tz;
clk(2)=timer;
zr=sz*tr;
clk(3)=timer;
zz=sz*tz;
clk(4)=timer;
rr=abs(double(rr) - builtin('mtimes',double(sr),double(tr)));
rz=abs(double(rz) - builtin('mtimes',double(sr),double(tz)));
zr=abs(double(zr) - builtin('mtimes',double(sz),double(tr)));
zz=abs(double(zz) - builtin('mtimes',double(sz),double(tz)));
err=mean(rr(:))+mean(rz(:))+mean(zr(:))+mean(zz(:));
% fprintf('       [%3d x %3d]*[%3d x %3d]%13dMFlops%18.3g\n',m,k,k,n,round(mean(ops./clk)),err);
fprintf('%13dMFlops%18.3g\n',round(mean(ops./clk)),err);
