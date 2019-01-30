%out=benchmark(opt)
%------------------
%
%Benchmark the performance of elementary MATLAB functions.
%
%To benchmark the double class functions (MEX files), call it from a folder
%containing "@double" with the double class functions. To benchmark MATLAB
%built-in functions, call it from elsewhere. For checking which function is
%executed, call "abs" without arguments. MATLAB built-ins return an error.
%The double class functions print a copyright notice instead.
%
%Input:
% opt    Benchmark options
%  .loop    Number of repetitions {2^15/sqrt(size)}
%  .name    List of function names {all}
%  .size    Matrix size {1,2,4,...,4096}
%
%Output:
% out    Benchmark results
%  .loop    Number of repetitions
%  .name    List of function names
%  .size    Matrix size
%  .call    Function call overhead [s]
%  .time    Overall execution time [s]
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

function out=benchmark(opt)
warning off;
clc;
%
% Fetch options
%
if ~nargin | ~isstruct(opt)
   opt=struct([]);
end
size=round(option(opt,'size',2.^(0:12))); size=ceil(size(:).');
loop=option(opt,'loop',2^15./sqrt(size)); loop=ceil(loop(:).');
name=option(opt,'name',{'abs';'acos';'acosh';'angle';'asin';'asinh';'atan';'atanh';'atan2';'ceil';'cos';'cosh';'exp';'fix';'floor';'log';'log2';'mod';'pow2';'rem';'round';'sign';'sin';'sinh';'sqrt';'tan';'tanh';'xor'});
%
% Save them
%
clear opt;
f=sort(who);
out.loop=1;
for n=1:length(f)
   out=setfield(out,f{n},eval(f{n}));
end
%
% Benchmark every function in the list
%
fprintf('\nBenchmark elementary MATLAB functions\n');
out.call=zeros(1,length(size));
out.time=zeros(length(name),length(size));
for k=1:length(size)
   S=size(k);
   L=loop(k);
   x=1e10*randn(S,1);
   y=1e10*randn(S,1);
   z=zeros(S,1);
   a=10*complex(randn(S,1),randn(S,1));
   b=10*complex(randn(S,1),z);
   c=10*complex(z,randn(S,1));
   d=10*randn(S,1);
   f=@abs;
   abs(a);
   timing;
   for n=1:L
      abs(a);
      abs(b);
      abs(c);
      abs(d);
   end
   t=timing;
   for n=1:L
      feval(f,a);
      feval(f,b);
      feval(f,c);
      feval(f,d);
   end
   T=timing;
   out.call(k)=T-t;
   fprintf('\n\n* Benchmark (%d/%d): %dms function call overhead\n',[S L round(1000*(T-t))]);
   for m=1:length(name)
      n=name{m};
      g=isequal(n,'atan2') | isequal(n,'mod') | isequal(n,'rem') | isequal(n,'xor');
      h=isequal(n,'angle') | isequal(n,'mod') | isequal(n,'xor');
      fprintf(['\n%2d.\t' n ':'],m);
      f=eval(['@' n]);
      drawnow;
      if g
         if h
            e=0;
         else
            e=abs([feval(f,x,y)-builtin(n,x,y) feval(f,y,x)-builtin(n,y,x) feval(f,x,z)-builtin(n,x,z) feval(f,z,y)-builtin(n,z,y)]);
         end
         timing;
         for n=1:L
            feval(f,x,y);
            feval(f,y,x);
            feval(f,x,z);
            feval(f,z,y);
         end
      else
         if h
            e=0;
         else
            e=abs([feval(f,a)-builtin(n,a) feval(f,b)-builtin(n,b) feval(f,c)-builtin(n,c) feval(f,d)-builtin(n,d)]);
         end
         timing;
         for n=1:L
            feval(f,a);
            feval(f,b);
            feval(f,c);
            feval(f,d);
         end
      end
      t=timing;
      out.time(m,k)=t;
      fprintf('\t\t%5dms',round(1e3*t));
      if any(e > 1e-12)
         fprintf(' failed\t%8d%8d%8d%8d',sum(e > 1e-6,1));
      end
   end
end


%Test for and extract a parameter's value.
%
%Input:
% o     Parameter structure
% n     Parameter name
% v     Default value
%
%Output:
% v     Value
%
function v=option(o,n,v)
if isfield(o,n) & isa(getfield(o,n),class(v))
   v=getfield(o,n);
end
if isnumeric(v)
   v=abs(v);
end


%Stopwatch timer.
%
%Output:
% time   Elapsed time since last call
%
function time=timing
persistent t;
if nargout
   if isempty(t)
      t=cputime;	%clock;
      time=0;
   else
      time=t;
      t=cputime;	%clock;
      time=t-time;	%etime(t,time);
   end
else
   t=cputime;		%clock;
end
