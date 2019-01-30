;Optimized double class functions for MATLAB on x86 computers.
;Copyright © Marcel Leutenegger, 2003-2008, École Polytechnique Fédérale de Lausanne (EPFL),
;Laboratoire d'Optique Biomédicale (LOB), BM - Station 17, 1015 Lausanne, Switzerland.
;
;    This library is free software; you can redistribute it and/or modify it under
;    the terms of the GNU Lesser General Public License as published by the Free
;    Software Foundation; version 2.1 of the License.
;
;    This library is distributed in the hope that it will be useful, but WITHOUT ANY
;    WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
;    PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
;
;    You should have received a copy of the GNU Lesser General Public License along
;    with this library; if not, write to the Free Software Foundation, Inc.,
;    51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

[segment .text align=16]
global	_fmov
global	_fset


;void fmov(double* or, const double* sr, int n)
;
_fmov:
	mov ecx,[esp+12]	; n
	mov eax,[esp+8]		; sr
	sub ecx,byte 1
	mov edx,[esp+4]		; or
.1:	fld qword [eax+ecx*8]
	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.1
       retn


align	4

;void fset(double* or, const double* sr, int n)
;
_fset:
	mov ecx,[esp+12]	; n
	mov eax,[esp+8]		; sr
	sub ecx,byte 1
	mov edx,[esp+4]		; or
	fld qword [eax]
.1:	fst qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.1
	ffree st0
       retn
