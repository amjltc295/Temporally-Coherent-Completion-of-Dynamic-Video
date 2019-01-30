%benchMtimes(m,k,n)
%------------------
%
%Benchmark the matrix multiplication and print typical error.
%
%    Marcel Leutenegger © 9.1.2005
%
%Input:
% m,k    Size of left matrix  {96x16}
% k,n    Size of right matrix {16x64}
%
function benchMtimes(m,k,n)
if nargin < 1 | isempty(m)
   m=96;
else
   m=m(1);
end
if nargin < 2 | isempty(k)
   k=16;
else
   k=k(1);
end
if nargin < 3 | isempty(n)
   n=64;
else
   n=n(1);
end
%
% Left (right) matrix s (t)
%
s=complex(randn(m,k),randn(m,k));
t=complex(randn(k,n),randn(k,n));
%
% Print header and test summaries
%
clc;
fprintf('\n        Benchmark matrix multiplication of class "double"');
fprintf('\n___________________________________________________________________\n');
% fprintf('\nTesting "mtimes":\n%34s%14s\n','speed','error');
fprintf('\nTesting "mtimes":\n%34s\n','speed');
dk=pow2(8:12);
for dk=dk(dk < 2*k)
   for dn=10:10:40
      run(s,t,dk,dn,2e3.*(8.*k-1));
   end
end


%Stopwatch the processing time (CPU clocks)
%
function run(s,t,dk,dn,ops)
N=4;
clk=zeros(N,1);
off=zeros(N,1);
for n=1:N
   timer;
   e=mul(s,t,dk,dn);
   clk(n,1)=timer;
   off(n,1)=timer;
end
% e=e - s*t;
% e=abs(e(:));
off=sort(off);
off=mean(off(1:N/2));
t=flipud(sort(ops.*numel(e)./(clk-off)));
t=t(1:N/2);
% fprintf('%9d*%3d%17dMFlops%15.3g\n',dk,dn,round(mean(t)),mean(sqrt(e.*e)));
fprintf('%9d*%3d%17dMFlops\n',dk,dn,round(mean(t)));
