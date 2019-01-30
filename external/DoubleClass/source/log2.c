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
*	    Base 2 logarithm and dissect floating point number		     *
*									     *
*									     *
*			Marcel Leutenegger © 12.5.2008			     *
*									     *
\****************************************************************************/

#include "mex.h"
#define	O	plhs[0]
#define	E	plhs[1]
#define	S	prhs[0]

bool flog2(double* or, double* oi, const double* sr, const double* si, int n);
void fxtract(double* or, double* er, const double* sr, int n);


void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{	const int* d;
	int m, n;
	if (nlhs > 2) mexErrMsgTxt("Too many output arguments.");
	switch(nrhs)
	{default:
		mexErrMsgTxt("Wrong number of input arguments.");
	 case 0:
		mexPrintf("\nBase 2 logarithm and dissect floating point number.\n\n\tMarcel Leutenegger © 12.5.2008\n\n");
		break;
	 case 1:
		O=mxCreateDoubleMatrix(0,0,mxREAL);
		mxSetDimensions(O,d=mxGetDimensions(S),m=mxGetNumberOfDimensions(S));
		n=mxGetNumberOfElements(S);
		if (nlhs > 1)
		{	if (mxIsComplex(S)) mexErrMsgTxt("Argument must be real.");
			E=mxCreateDoubleMatrix(0,0,mxREAL);
			mxSetDimensions(E,d,m);
			if (n > 0)
			{	double *or, *er;
				mxSetPr(O,or=mxMalloc(n*sizeof(double)));
				mxSetPr(E,er=mxMalloc(n*sizeof(double)));
				fxtract(or,er,mxGetPr(S),n);
			}
			break;
		}
		if (n > 0)
		{	double *or, *oi=mxMalloc(n*sizeof(double));
			mxSetPr(O,or=mxMalloc(n*sizeof(double)));
			if (flog2(or,oi,mxGetPr(S),mxGetPi(S),n)) mxSetPi(O,oi);
		}
	}
}
