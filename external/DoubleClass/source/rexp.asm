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

;Optimized routine for calculating the exponential of a real, finite number.
;
;See also:
;
; [1]	Agner Fog, "Optimizing subroutines in assembly language," at
;	Copenhagen University College of Engineering, www.agner.org.
;
;By the way:
;
;	Agner Fog also states that he had never found a situation, where a
;	repeated execution of FPREM was necessary to complete the reduction
;	(modulus) of a number. On Pentium 4 processors, I could verify that
;	for very large ratios of dividend versus divisor, FPREM effectively
;	requires repeated execution to complete.
;
;	In this code, FPREM is used to reduce the argument of cosine, sine
;	and tangent. It is of course questionable if very large arguments
;	should be treated at all, as the round-off error increases egally,
;	but without proper reduction, the result would be garbage anyhow.
;
;
[segment .data align=16]
finf:	dd	0x7F800000	; inf


[segment .text align=16]
global	_rexp


;>>	st0 = R
;
;[st0..2,eax]
;
;<<	st0 = exp(R)
;
_rexp:
	fldl2e
	fmulp st1,st0
	sub esp,byte 16
	fist dword [esp]
	mov dword [esp+4],0
	mov dword [esp+8],0x80000000
	fisub dword [esp]
	pop eax
	add eax,0x3FFF
	mov [esp+8],eax
       jle	.1
	cmp eax,0x8000
       jge	.2
	f2xm1
	fld1
	faddp st1,st0
	fld tword [esp]		; aligned if esp is aligned before call
	add esp,byte 12
	fmulp st1,st0
       retn
.1:	fldz
	fstp st1
	add esp,byte 12
       retn
.2:	fld dword [finf]
	add esp,byte 12
	fstp st1
       retn
