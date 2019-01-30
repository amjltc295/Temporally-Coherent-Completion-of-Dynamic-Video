%Array power.
%
%    Marcel Leutenegger © 12.1.2005
%
function o=power(s,t)
if isempty(s)
   o=[];
   return;
end
switch prod(size(t))
case 0
   o=[];
case 1
   switch t
   case 0
      o=ones(size(s));
   case 0.5
      o=sqrt(s);
   case 1
      o=s;
   case 2
      o=s.*s;
   case 3
      o=s.*s.*s;
   case 4
      o=s.*s;
      o=o.*o;
   case 5
      o=s.*s;
      o=o.*o.*s;
   case 6
      o=s.*s;
      o=o.*o.*o;
   case 7
      o=s.*s.*s;
      o=o.*o.*s;
   case 8
      o=s.*s;
      o=o.*o;
      o=o.*o;
   case 9
      o=s.*s;
      o=o.*o;
      o=o.*o.*s;
   case 10
      o=s.*s;
      o=o.*o.*s;
      o=o.*o;
   case 12
      o=s.*s;
      o=o.*o;
      o=o.*o.*o;
   case 16
      o=s.*s;
      o=o.*o;
      o=o.*o;
      o=o.*o;
   otherwise
      o=exp(log(s)*t);
   end
otherwise
   o=exp(log(s).*t);
end
