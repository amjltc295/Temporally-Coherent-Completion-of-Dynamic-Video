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

;	The functions here use the FPU partial arcustangens even for
;	input (scalar,matrix) respectively (matrix,scalar) with zero
;	scalar. The correct response reflects the sign of this zero
;	value ->> observe them in case of manual coding.


[segment .text align=16]
global	_fmatan2
global	_fsatan2
global	_ftatan2


;void fxatan2(double* or, const double* sr, const double* tr, int n)
;
_fmatan2:
	push ebx
	fninit
	mov ecx,[esp+20]	; n
	mov ebx,[esp+16]	; tr
	sub ecx,byte 1
	mov eax,[esp+12]	; sr
	mov edx,[esp+8]		; or
.1:	fld qword [eax+ecx*8]
	fucomi st0
       jp	.2
	fld qword [ebx+ecx*8]
	fucomi st0
       jp	.2
	fpatan
.2:	fstp qword [edx+ecx*8]
	sub ecx,byte 1
	ffree st0
       jns	.1
	pop ebx
       retn


align	4

_fsatan2:
	push ebx
	fninit
	mov ecx,[esp+20]	; n
	mov ebx,[esp+16]	; tr
	sub ecx,byte 1
	mov eax,[esp+12]	; sr
	mov edx,[esp+8]		; or
	fld qword [eax]
	fucomi st0
       jp	.3
.1:	fld st0
	fld qword [ebx+ecx*8]
	fucomi st0
       jp	.2
	fpatan
	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.1
	ffree st0
	pop ebx
       retn
.2:	fstp st1
	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.1
	ffree st0
	pop ebx
       retn
.3:	fst qword [edx+ecx*8]	; nan
	sub ecx,byte 1
       jns	.3
	ffree st0
	pop ebx
       retn


align	4

_ftatan2:
	push ebx
	fninit
	mov ecx,[esp+20]	; n
	mov ebx,[esp+16]	; tr
	sub ecx,byte 1
	mov eax,[esp+12]	; sr
	mov edx,[esp+8]		; or
	fld qword [ebx]
	fucomi st0
       jp	.3
.1:	fld qword [eax+ecx*8]
	fucomi st0
       jp	.2
	fld st1
	fpatan
.2:	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.1
	ffree st0
	pop ebx
       retn
.3:	fst qword [edx+ecx*8]	; nan
	sub ecx,byte 1
       jns	.3
	ffree st0
	pop ebx
       retn
