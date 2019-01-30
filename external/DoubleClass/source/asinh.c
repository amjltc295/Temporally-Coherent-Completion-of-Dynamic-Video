/*
  Optimized double class functions for MATLAB on x86 computers.
  Copyright © Marcel Leutenegger, 2003-2008, École Polytechnique Fédérale de Lausanne (EPFL),
  Laboratoire d'Optique Biomédicale (LOB), BM - Station 17, 1015 Lausanne, Switzerland.

      This library is free software; you can redistribute it and/or modify it under
      the terms of the GNU Lesser General Public License as published by the Free
      Software Foundation; version 2.1 of the License.

      This library is distributed in the hope that it will be useful, but WITHOUT ANY
      WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
      PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

      You should have received a copy of the GNU Lesser General Public License along
      with this library; if not, write to the Free Software Foundation, Inc.,
      51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

/****************************************************************************\
*									     *
*			   Inverse hyperbolic sine			     *
*									     *
*									     *
*			Marcel Leutenegger © 12.5.2008			     *
*									     *
\****************************************************************************/

#include "mex.h"
#define	O	plhs[0]
#define	S	prhs[0]

void fasinh(double* or, double* oi, const double* sr, const double* si, int n);


void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{	int n;
	if (nlhs > 1) mexErrMsgTxt("Too many output arguments.");
	switch(nrhs)
	{default:
		mexErrMsgTxt("Wrong number of input arguments.");
	 case 0:
		mexPrintf("\nInverse hyperbolic sine.\n\n\tMarcel Leutenegger © 12.5.2008\n\n");
		break;
	 case 1:
		O=mxCreateDoubleMatrix(0,0,mxREAL);
		mxSetDimensions(O,mxGetDimensions(S),mxGetNumberOfDimensions(S));
		n=mxGetNumberOfElements(S);
		if (n > 0)
		{	double *or, *oi=NULL;
			mxSetPr(O,or=mxMalloc(n*sizeof(double)));
			if (mxIsComplex(S)) mxSetPi(O,oi=mxMalloc(n*sizeof(double)));
			fasinh(or,oi,mxGetPr(S),mxGetPi(S),n);
		}
	}
}
