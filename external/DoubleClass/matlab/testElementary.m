%testElementary(typ,a,b,f)
%-------------------------
%
%Test the elementary functions and determine typical errors.
%
%The inverse cosine and the inverse cosine hyperbolicus may
%differ from MATLAB (sign). They are implemented as described
%in "Implementation.pdf".
%
%Input:
% typ    Conversion function handle for test data type {@double}
% a/b    First/second operand standard deviation {10}
% f      File name for output
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

function testElementary(typ,a,b,f)
if nargin < 1 | isempty(typ)
   typ=@double;
end
if nargin < 2 | isempty(a)
   a=10;
else
   a=a(1);
end
if nargin < 3 | isempty(b)
   b=10;
else
   b=b(1);
end
if nargin > 3 & ischar(f)
   h=max(2,fopen(f,'w'));
else
   h=2;
end
%
% Test functions: err={fun (s) end}
%
fun={'abs','-builtin(''abs'',s{n})';      % complex numbers
   'angle','-builtin(''atan2'',imag(s{n}),real(s{n}))';
   'sign','-builtin(''sign'',s{n})';
   'sqrt','-builtin(''sqrt'',s{n})';
   'ceil','-builtin(''ceil'',s{n})';      % rounding to integer
   'fix','-builtin(''fix'',s{n})';
   'floor','-builtin(''floor'',s{n})';
   'round','-builtin(''round'',s{n})';
   'acos','-builtin(''acos'',s{n})';      % inverse transcendentals
   'acosh','-builtin(''acosh'',s{n})';
   'asin','-builtin(''asin'',s{n})';
   'asinh','-builtin(''asinh'',s{n})';
   'atan','-builtin(''atan'',s{n})';
   'atanh','-builtin(''atanh'',s{n})';
   'log','-builtin(''log'',s{n})';
   'log2','-builtin(''log2'',s{n})';
   'log10','-builtin(''log'',s{n})/log(10)';
   'cos','./builtin(''cos'',s{n})-1';     % transcendentals
   'cosh','./builtin(''cosh'',s{n})-1';
   'sin','./builtin(''sin'',s{n})-1';
   'sinh','./builtin(''sinh'',s{n})-1';
   'tan','./builtin(''tan'',s{n})-1';
   'tanh','./builtin(''tanh'',s{n})-1';
   'exp','./builtin(''exp'',s{n})-1';
   'pow2','./builtin(''pow2'',s{n})-1'};
ref={'abs(sign',')-1';                    % self consistency
   'sqrt','.^2./s{n}-1';
   'cos(acos',')./s{n}-1';
   'cosh(acosh',')./s{n}-1';
   'sin(asin',')./s{n}-1';
   'sinh(asinh',')./s{n}-1';
   'tan(atan',')./s{n}-1';
   'tanh(atanh',')./s{n}-1';
   'exp(log',')./s{n}-1';
   'pow2(log2',')./s{n}-1';
   'exp(log(10)*log10',')./s{n}-1'};
%
% Input arguments
%
p={'R','R+0i','iR','R+iR'};
s={a*randn(128),complex(a*randn(128)),complex(0,b*randn(128)),complex(a*randn(128),b*randn(128))};
t={feval(typ,s{1}),feval(typ,s{2}),feval(typ,s{3}),feval(typ,s{4})};
%
% Print header and test summaries
%
if h > 2
   fprintf('\n        Test the elementary functions of class "%s" ... ',func2str(typ));
else
   clc;
end
fprintf(h,'\n        Test the elementary functions of class "%s"',func2str(typ));
fprintf(h,'\n___________________________________________________________________\n');
for m=1:size(fun,1)
   fprintf(h,'\nTesting "%s":\n%32s%16s%16s\n',fun{m,1},'min','rms','max');
   str=sprintf('e=double(%s(t{n}))%s;',fun{m,:});
   for n=1:4
      eval(str,'e=nan;');
      e=builtin('abs',e(:));
      fprintf(h,'%9s(%s)\t%19.3g%16.3g%16.3g\n',fun{m,1},p{n},min(e),sqrt(mean(e.*e)),max(e));
   end
end
%
% Test self consistency
%
for m=1:size(ref,1)
   fprintf(h,'\nTesting "%s(s{n})%s":\n%32s%16s%16s\n',ref{m,:},'min','rms','max');
   str=sprintf('e=double(%s(t{n}))%s;',ref{m,:});
   for n=1:4
      eval(str,'e=nan;');
      e=builtin('abs',e(:));
      fprintf(h,'%9s(%s)\t%19.3g%16.3g%16.3g\n','s{n}=',p{n},min(e),sqrt(mean(e.*e)),max(e));
   end
end
if h > 2
   fclose(h);
   fprintf('done\n\n');
end
