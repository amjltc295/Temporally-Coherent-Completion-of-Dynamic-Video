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
global	_fmrem
global	_fsrem
global	_ftrem


;void fxrem(double* or, const double* sr, const double* tr, int n)
;
_fmrem:
	push edi
	push esi
	fninit
	mov ecx,[esp+24]	; n
	mov esi,[esp+20]	; tr
	sub ecx,byte 1
	mov edi,[esp+16]	; sr
	mov edx,[esp+12]	; or
.1:	fld qword [esi+ecx*8]
	fucomi st0
       jp	.3
	fld qword [edi+ecx*8]
	fucomi st0
       jp	.3
.2:	fprem
	fnstsw ax
	sahf
       jp	.2
.3:	fstp qword [edx+ecx*8]
	sub ecx,byte 1
	ffree st0
       jns	.1
	pop esi
	pop edi
       retn


align	4

_fsrem:
	push ebx
	fninit
	mov ecx,[esp+20]	; n
	mov ebx,[esp+12]	; sr
	sub ecx,byte 1
	fld qword [ebx]
	mov ebx,[esp+16]	; tr
	fucomi st0
	mov edx,[esp+8]		; or
       jp	.4
.1:	fld qword [ebx+ecx*8]
	fucomi st0
       jp	.3
	fld st1
.2:	fprem
	fnstsw ax
	sahf
       jp	.2
	fstp st1
.3:	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.1
	ffree st0
	pop ebx
       retn
.4:	fst qword [edx+ecx*8]	; nan
	sub ecx,byte 1
       jns	.4
	ffree st0
	pop ebx
       retn


align	4

_ftrem:
	push ebx
	fninit
	mov ecx,[esp+20]	; n
	mov ebx,[esp+16]	; tr
	sub ecx,byte 1
	fld qword [ebx]
	mov ebx,[esp+12]	; sr
	fucomi st0
	mov edx,[esp+8]		; or
       jp	.4
.1:	fld qword [ebx+ecx*8]
	fucomi st0
       jp	.3
.2:	fprem
	fnstsw ax
	sahf
       jp	.2
.3:	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.1
	ffree st0
	pop ebx
       retn
.4:	fst qword [edx+ecx*8]	; nan
	sub ecx,byte 1
       jns	.4
	ffree st0
	pop ebx
       retn
