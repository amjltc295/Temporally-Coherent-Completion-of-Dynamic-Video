%mexmake(opt,...)
%----------------
%
%Compile assembler files and build MEX-function.
%
%  Loads the "version.mat" from the current folder to
%  include and update the file version information.
%
% opt    Options {'-O'}
% ...    MEX-functions {all}
%
%The compilation of selected files increases their file
%build number. In case of all files, the product build
%number is increased too.
%
%   Marcel Leutenegger © 21.7.2006
%
function mexmake(o,varargin)
v='version.mat';
if nargin > 1 & any(findstr(varargin{1},v))
   v=varargin{1};
   m=2;
else
   m=1;
end
load(v,'f','p');
if nargin < 1
   o='-O';
end
mexrun('lcc',['-Fo"mexstub.obj" -c "' fullfile(matlabroot,'sys','lcc','mex','lccstub.c') '"'],o);
if any(findstr(o,'-inline'))
   p.Comments='MEX-function for MATLAB 6.0.';
   p.SpecialBuild='Inlined matrix accessor functions.';
else
   p.Comments='MEX-function for MATLAB 6.0 or newer.';
   if isfield(p,'SpecialBuild')
      p=rmfield(p,'SpecialBuild');
   end
end
if nargin > m        % build particular function(s)
   for n=m:nargin-1
      [path,file]=fileparts(varargin{n});
      m=strmatch([fullfile(path,file) '.'],{f(:).FileName});
      if numel(m) == 1
         f(m)=compile(o,f(m),p);
         save(v,'f','p');
      else
         warning(['Have no information on "' varargin{n} '".']);
      end
   end
else                 % build entire product
   for m=1:numel(f)
      f(m)=compile(o,f(m),p);
      save(v,'f','p');
   end
   p.ProductVersion(4)=p.ProductVersion(4)+1;
end
save(v,'f','p');
clear classes
delete *.obj


%Compile, assemble and link a MEX-function
%
% o      Options
% f      File information
% p      Product information
%
function f=compile(o,f,p)
obj='';
stub='mexstub.obj';
for n=1:numel(f.Files)
   if isequal(f.Files{n},'-nostub')
      stub='';
      continue
   end
   [path,file,ext]=fileparts(f.Files{n});
   path=fullfile(path,file);
   file=[path '.obj'];
   if exist(file) ~= 2
      switch ext
      case '.asm'
         eval(['!"C:\Program files\Netwide Assembler\nasmw.exe" -f win32 -o "' file '" "' f.Files{n} '"']);
         if exist(file) ~= 2
            error(['Could not assemble "' f.Files{n} '".']);
         end
      case '.dll'
         eval(['!"' fullfile(matlabroot,'sys','lcc','bin','implib') '" "' f.Files{n} '"']);
         file=[path '.lib'];
      case '.exp'
         eval(['!"' fullfile(matlabroot,'sys','lcc','bin','buildlib') '" "' f.Files{n} '"']);
         file=[path '.lib'];
      case '.lib'
         file=[path '.lib'];
      case '.f'
         mexrun('f2c',['"' f.Files{n} '"']);
         mexrun('lcc',['-Fo"' file '" -c "' path '.c"'],o);
      case {'.c','.cpp'}
         mexrun('lcc',['-Fo"' file '" -c "' f.Files{n} '"'],o);
      otherwise
         error(['Have no compiler for "' f.Files{n} '".']);
      end
   end
   obj=[obj ' "' file '"'];
end
f=mexinfo(f,p,o);
[path,file,ext]=fileparts(f.FileName);
file=fullfile(path,file);
mexrun('lrc',[file '.rc']);
% mexrun('lcclnk',['-dll -o "' file ext '" -tmpdir "." "' fullfile(matlabroot,'extern','lib','win32','lcc','mexFunction.def') '" "' file '.res" ' obj ' ' stub ' -s libmx.lib libmex.lib libmatlbmx.lib libmat.lib']);
%
% lcc-win32 3.2
%
mexrun('lcclnk',['-dll -o "' file ext '" "' fullfile(matlabroot,'extern','lib','win32','lcc','mexFunction.def') '" "' file '.res" ' obj ' ' stub ' -s libmx.lib libmex.lib libmatlbmx.lib libmat.lib']);
delete([file '.exp'],[file '.lib'],[file '.res'],[file '.rc']);


%Create a version information resource and increment the build number.
%
% f      File information
%  .FileDescription     Description
%  .FileName            Name of MEX-function
%  .FileVersion         File version [major,minor,patch,build]
%
% p      Product information
%  .ProductName         Product name
%  .ProductVersion      Product version [major,minor,patch,build]
%
%        Common information
%  .Comments
%  .CompanyName
%  .LegalCopyright
%  .LegalTrademarks
%  .PrivateBuild
%  .SpecialBuild
%
% o      Build options
%
function f=mexinfo(f,p,o)
n=fieldnames(f);
for m=1:numel(n)
   v=getfield(f,n{m});
   if numel(v)
      p=setfield(p,n{m},v);
   end
end
[path,file,ext]=fileparts(p.FileName);
p.InternalName=file;
p.OriginalFilename=[file ext];
h=fopen([fullfile(path,file) '.rc'],'w');
if h < 0
   error(['Could not create the version resource for "' file ext '".']);
end
p=rmfield(p,'FileName');
p=rmfield(p,'Files');
fprintf(h,'#include "winver.h"\n1 VERSIONINFO\n');
fprintf(h,' FILEOS VOS__WINDOWS32\n');
fprintf(h,' FILETYPE VFT_DLL\n');
fprintf(h,' FILESUBTYPE 0\n');
s='0';
if isfield(p,'PrivateBuild')
   s='VS_FF_PRIVATEBUILD';
end
if isfield(p,'SpecialBuild')
   if numel(s) > 1
      s=[s '+VS_FF_SPECIALBUILD'];
   else
      s='VS_FF_SPECIALBUILD';
   end
end
fprintf(h,' FILEFLAGS %s\n',s);
fprintf(h,' FILEFLAGSMASK %s\n',s);
fprintf(h,' FILEVERSION %d,%d,%d,%d\n',p.FileVersion);
fprintf(h,' PRODUCTVERSION %d,%d,%d,%d\n',p.ProductVersion);
fprintf(h,'BEGIN\n BLOCK "StringFileInfo"\n BEGIN\n  BLOCK "040904b0"\n  BEGIN\n');
n=sort(fieldnames(p));
p.FileVersion=sprintf('%d.%d.%d.%d',p.FileVersion);
p.ProductVersion=sprintf('%d.%d.%d.%d',p.ProductVersion);
for m=1:numel(n)
   fprintf(h,'   VALUE "%s","%s"\n',n{m},getfield(p,n{m}));
end
fprintf(h,'  END\n END\n BLOCK "VarFileInfo"\n BEGIN\n  VALUE "Translation",0x0409,0\n END\nEND\n');
%
% matlabroot\extern\include\mexversion.rc
%
fprintf(h,'\n\nSTRINGTABLE\nBEGIN\n');
fprintf(h,' 100,"MATLAB R11 native"\n');
if nargin > 2 & any(findstr(o,'-inline'));
   fprintf(h,' 101,"inlined"\n');
else
   fprintf(h,' 101,"not inlined"\n');
end
fprintf(h,'END\n');
fclose(h);
f.FileVersion(4)=f.FileVersion(4)+1;


%Run a compiler command (lcc, lrc, lcclnk) and check output.
%
% c      Compiler command
% p      Parameters
% o      Options
%
function mexrun(c,p,o)
if isequal(c,'lcc')
   p=[p ' -O -Zp8 -DMATLAB_MEX_FILE -DNDEBUG'];
   if nargin > 2 & findstr(o,'-inline');
      p=[p ' -DARRAY_ACCESS_INLINING'];
   end
else
   if nargin > 2
      p=[p ' ' o];
   end
end
if isequal(c,'lcclnk')
%    p=['-L"' fullfile(matlabroot,'sys','lcc','lib') '" -libpath "' fullfile(matlabroot,'extern','lib','win32','lcc') '" ' p];
%
% lcc-win32 3.2
%
   p=['-L"' fullfile(matlabroot,'sys','lcc','lib') '" -L"' fullfile(matlabroot,'extern','lib','win32','lcc') '" ' p];
else
%    p=['-noregistrylookup -I"' fullfile(matlabroot,'extern','include') '" -I"' fullfile(matlabroot,'simulink','include') '" -I"' fullfile(matlabroot,'sys','lcc','include') '" ' p];
%
% lcc-win32 3.2
%
   p=['-I"' fullfile(matlabroot,'extern','include') '" -I"' fullfile(matlabroot,'simulink','include') '" -I"' fullfile(matlabroot,'sys','lcc','include') '" ' p];
end
t=evalc(['!"' fullfile(matlabroot,'sys','lcc','bin',c) '" ' p]);
if numel(t)
   if any(strmatch('Error',t))
      error(t);
   else
      fprintf('%s:\n%s\n',c,t);
   end
end
