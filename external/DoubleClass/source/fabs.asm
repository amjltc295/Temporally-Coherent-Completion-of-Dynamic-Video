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
global	_fabs


;void fabs(double* or, const double* sr, const double* si, int n)
;
_fabs:
	push edi
	push esi
	fninit
	mov ecx,[esp+24]	; n
	mov esi,[esp+20]	; si
	sub ecx,byte 1
	mov edi,[esp+16]	; sr
	test esi,esi
	mov edx,[esp+12]	; or
       jz	.6
	add edx,byte 8
.1:	fld qword [edi+ecx*8]
	fxam
	fnstsw ax
	sahf
       jc	.2
       jz	.4
	fld qword [esi+ecx*8]
	fxam
	fnstsw ax
	sahf
       jc	.5
       jz	.3
	sub ecx,byte 1
	fmul st0,st0
	fxch
	fmul st0,st0
	faddp st1,st0
	fsqrt
	fstp qword [edx+ecx*8]
       jns	.1
	pop esi
	pop edi
       retn
.2:    jnp	.5
	fld qword [esi+ecx*8]
	fxam
	fnstsw ax
	sahf
       jnc	.3
       jnp	.5
.3:	sub ecx,byte 1
	fstp st0
	fabs
	fstp qword [edx+ecx*8]
       jns	.1
	pop esi
	pop edi
       retn
.4:	fld qword [esi+ecx*8]
.5:	sub ecx,byte 1
	ffree st1
	fabs
	fstp qword [edx+ecx*8]
       jns	.1
	pop esi
	pop edi
       retn
.6:	fld qword [edi+ecx*8]	; real
	fabs
	fstp qword [edx+ecx*8]
	sub ecx,byte 1
       jns	.6
	pop esi
	pop edi
       retn
