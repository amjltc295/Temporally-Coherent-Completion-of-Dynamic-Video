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
*			    Matrix multiplication			     *
*			     SSE2 implementation			     *
*									     *
*			Marcel Leutenegger © 17.9.2008			     *
*									     *
\****************************************************************************/

#include "mex.h"
#define	O	plhs[0]
#define	S	prhs[0]
#define	T	prhs[1]


/****************************************************************************\
*									     *
*		SSE2 initialisation, vector and scalar product		     *
*									     *
\****************************************************************************/

void fxinit(void);
void fmtimes(double* or, double* oi, const double* sr, const double* si, const double* tr, const double* ti, int k);
void fstimes(double* or, double* oi, const double* sr, const double* si, const double* tr, const double* ti, int n);
void fvtimes(double* or, double* oi, const double* sr, const double* si, const double* tr, const double* ti, int m, int n);


/****************************************************************************\
*									     *
*			   Blocked matrix product			     *
*									     *
\****************************************************************************/

/*	 Align and pack s(1:X,1:n) for faster memory access by SSE
	 operations. The matrix s has dimensions [m x n]. o has to
	 be aligned to a 128byte boundary.
*/
void align10mn(double* o, const double* s, int m, int n);
void align9mn(double* o, const double* s, int m, int n);
void align8mn(double* o, const double* s, int m, int n);
void align7mn(double* o, const double* s, int m, int n);
void align6mn(double* o, const double* s, int m, int n);
void align5mn(double* o, const double* s, int m, int n);
void align4mn(double* o, const double* s, int m, int n);
void align3mn(double* o, const double* s, int m, int n);
void align2mn(double* o, const double* s, int m, int n);
void align1mn(double* o, const double* s, int m, int n);

/*	Unpack and store a block to o(1:X,1:n). The matrix o has
	dimensions [m x n]. The matrix s has to be storeed to a
	128byte boundary.
*/
void store10mn(double* o, const double* s, int m, int n);
void store9mn(double* o, const double* s, int m, int n);
void store8mn(double* o, const double* s, int m, int n);
void store7mn(double* o, const double* s, int m, int n);
void store6mn(double* o, const double* s, int m, int n);
void store5mn(double* o, const double* s, int m, int n);
void store4mn(double* o, const double* s, int m, int n);
void store3mn(double* o, const double* s, int m, int n);
void store2mn(double* o, const double* s, int m, int n);
void store1mn(double* o, const double* s, int m, int n);

/*	Initialize a block [dm x dk]*[dk x dn].
*/
void init10kn(double* o, const double* s, const double* t, int k, int dk, int dn);
void init8kn(double* o, const double* s, const double* t, int k, int dk, int dn);
void init6kn(double* o, const double* s, const double* t, int k, int dk, int dn);
void init4kn(double* o, const double* s, const double* t, int k, int dk, int dn);
void init2kn(double* o, const double* s, const double* t, int k, int dk, int dn);

/*	Add [dm x dk]*[dk x dn] with a block.
*/
void madd10kn(double* o, const double* s, const double* t, int k, int dk, int dn);
void madd8kn(double* o, const double* s, const double* t, int k, int dk, int dn);
void madd6kn(double* o, const double* s, const double* t, int k, int dk, int dn);
void madd4kn(double* o, const double* s, const double* t, int k, int dk, int dn);
void madd2kn(double* o, const double* s, const double* t, int k, int dk, int dn);

/*	Subtract [dm x dk]*[dk x dn] from a block.
*/
void msub10kn(double* o, const double* s, const double* t, int k, int dk, int dn);
void msub8kn(double* o, const double* s, const double* t, int k, int dk, int dn);
void msub6kn(double* o, const double* s, const double* t, int k, int dk, int dn);
void msub4kn(double* o, const double* s, const double* t, int k, int dk, int dn);
void msub2kn(double* o, const double* s, const double* t, int k, int dk, int dn);


static	int m=0, k=0, n=0;
static	int fk=0, nk=0, lk=0;
static	const int dk=1024, dn=40;
static	void (*const alignXmn[9])(double*,const double*,int,int)={align1mn,align2mn,align3mn,align4mn,align5mn,align6mn,align7mn,align8mn,align9mn};
static	void (*const storeXmn[9])(double*,const double*,int,int)={store1mn,store2mn,store3mn,store4mn,store5mn,store6mn,store7mn,store8mn,store9mn};
static	void (*const initXkn[5])(double*,const double*,const double*,int,int,int)={init2kn,init4kn,init6kn,init8kn,init10kn};
static	void (*const maddXkn[5])(double*,const double*,const double*,int,int,int)={madd2kn,madd4kn,madd6kn,madd8kn,madd10kn};
static	void (*const msubXkn[5])(double*,const double*,const double*,int,int,int)={msub2kn,msub4kn,msub6kn,msub8kn,msub10kn};


/*	Multiply and update [dm x k]*[k x dn].
*/
void block(double* o, const double* s, const double* t, int dm, int dn, void (*const init)(double*,const double*,const double*,int,int,int), void (*const step)(double*,const double*,const double*,int,int,int))
{	int kk=nk;
	init(o,s,t,k,fk,dn);
	s+=fk*dm;
	t+=fk;
	while(kk-- > 0)
	{	step(o,s,t,k,dk,dn);
		s+=dk*dm;
		t+=dk;
	}
	if (lk > 0) step(o,s,t,k,lk,dn);
}


/*	Multiply [m x k]*[k x n].
*/
void init(double* o, double* s, double* or, const double* sr, const double* tr)
{	int mm=m, nn;
	while(mm > 9)
	{	double* os=or;
		double* ts=tr;
		nn=n;
		align10mn(s,sr,m,k);
		while(nn > dn+3)
		{	block(o,s,ts,10,dn,init10kn,madd10kn);
			store10mn(os,o,m,dn);
			os+=dn*m;
			ts+=dn*k;
			nn-=dn;
		}
		if (nn > dn)
		{	int dn=nn/2;
			block(o,s,ts,10,dn,init10kn,madd10kn);
			store10mn(os,o,m,dn);
			os+=dn*m;
			ts+=dn*k;
			nn-=dn;
		}
		block(o,s,ts,10,nn,init10kn,madd10kn);
		store10mn(os,o,m,nn);
		or+=10;
		sr+=10;
		mm-=10;
	}
	if (mm-- > 0)
	{	void (*align)(double*,const double*,int,int)=alignXmn[mm];
		void (*store)(double*,const double*,int,int)=storeXmn[mm];
		void (*init)(double*,const double*,const double*,int,int,int)=initXkn[mm>>=1];
		void (*step)(double*,const double*,const double*,int,int,int)=maddXkn[mm++];
		mm<<=1;
		nn=n;
		align(s,sr,m,k);
		while(nn > dn+3)
		{	block(o,s,tr,mm,dn,init,step);
			store(or,o,m,dn);
			or+=dn*m;
			tr+=dn*k;
			nn-=dn;
		}
		if (nn > dn)
		{	int dn=nn/2;
			block(o,s,tr,mm,dn,init,step);
			store(or,o,m,dn);
			or+=dn*m;
			tr+=dn*k;
			nn-=dn;
		}
		block(o,s,tr,mm,nn,init,step);
		store(or,o,m,nn);
	}
}


/*	Update [m x k]*[k x n].
*/
void done(double* o, double* s, double* or, const double* sr, const double* tr, void (*const steps[])(double*,const double*,const double*,int,int,int))
{	void (*step)(double*,const double*,const double*,int,int,int)=steps[4];
	int mm=m, nn;
	while(mm > 9)
	{	double* os=or;
		double* ts=tr;
		nn=n;
		align10mn(s,sr,m,k);
		while(nn > dn+3)
		{	align10mn(o,os,m,dn);
			block(o,s,ts,10,dn,step,step);
			store10mn(os,o,m,dn);
			os+=dn*m;
			ts+=dn*k;
			nn-=dn;
		}
		if (nn > dn)
		{	int dn=nn/2;
			align10mn(o,os,m,dn);
			block(o,s,ts,10,dn,step,step);
			store10mn(os,o,m,dn);
			os+=dn*m;
			ts+=dn*k;
			nn-=dn;
		}
		align10mn(o,os,m,nn);
		block(o,s,ts,10,nn,step,step);
		store10mn(os,o,m,nn);
		or+=10;
		sr+=10;
		mm-=10;
	}
	if (mm-- > 0)
	{	void (*align)(double*,const double*,int,int)=alignXmn[mm];
		void (*store)(double*,const double*,int,int)=storeXmn[mm];
		step=steps[mm>>=1];
		mm<<=1;
		mm+=2;
		nn=n;
		align(s,sr,m,k);
		while(nn > dn+3)
		{	align(o,or,m,dn);
			block(o,s,tr,mm,dn,step,step);
			store(or,o,m,dn);
			or+=dn*m;
			tr+=dn*k;
			nn-=dn;
		}
		if (nn > dn)
		{	int dn=nn/2;
			align(o,or,m,dn);
			block(o,s,tr,mm,dn,step,step);
			store(or,o,m,dn);
			or+=dn*m;
			tr+=dn*k;
			nn-=dn;
		}
		align(o,or,m,nn);
		block(o,s,tr,mm,nn,step,step);
		store(or,o,m,nn);
	}
}


void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{	bool sz, tz;
	double *or, *oi=NULL;
	if (nlhs > 1) mexErrMsgTxt("Too many output arguments.");
	switch(nrhs)
	{default:
		mexErrMsgTxt("Wrong number of input arguments.");
	 case 0:
		mexPrintf("\nMatrix multiplication.\n\n\tMarcel Leutenegger © 17.9.2008\n\n");
		break;
	 case 2:
		sz=mxIsComplex(S);
		tz=mxIsComplex(T);
		m=mxGetNumberOfElements(S);
		n=mxGetNumberOfElements(T);
		O=mxCreateDoubleMatrix(0,0,mxREAL);
		if (m == 1)	// scalar * matrix
		{	mxSetDimensions(O,mxGetDimensions(T),mxGetNumberOfDimensions(T));
			if (n > 0)
			{	mxSetData(O,or=mxMalloc(m=n*sizeof(double)));
				if (sz || tz) mxSetImagData(O,oi=mxMalloc(m));
				fstimes(or,oi,mxGetData(S),mxGetImagData(S),mxGetData(T),mxGetImagData(T),n);
			}
			break;
		}
		if (n == 1)	// matrix * scalar
		{	mxSetDimensions(O,mxGetDimensions(S),mxGetNumberOfDimensions(S));
			if (m > 0)
			{	mxSetData(O,or=mxMalloc(n=m*sizeof(double)));
				if (sz || tz) mxSetImagData(O,oi=mxMalloc(n));
				fstimes(or,oi,mxGetData(T),mxGetImagData(T),mxGetData(S),mxGetImagData(S),m);
			}
			break;
		}
		k=mxGetN(S);	// matrix * matrix
		if (mxGetNumberOfDimensions(S)*mxGetNumberOfDimensions(T) == 4 && k == mxGetM(T))
		{	mxSetM(O,m/=k);
			mxSetN(O,n/=k);
			if (m > 0 && n > 0)
			{	mxSetData(O,or=mxMalloc(m*n*sizeof(double)));
				if (sz || tz) mxSetImagData(O,oi=mxMalloc(m*n*sizeof(double)));
				if (k > 1)
				{	double *os, *ss;
					if (m*n == 1)
					{	fmtimes(or,oi,mxGetData(S),mxGetImagData(S),mxGetData(T),mxGetImagData(T),k);
						break;
					}
					nk=(k < dk+dk/2)? 0: (k + dk/2)/dk - 1;
					fk=k - dk*nk;
					lk=0;
					if (fk > dk)
					{	fk/=2;
						lk=k - dk*nk - fk;
					}
					fxinit();
					os=(double*)((unsigned)mxMalloc(80*dn+128)+127 & 0xFFFFFF80);
					ss=(double*)((unsigned)mxMalloc(80*k+128)+127 & 0xFFFFFF80);
					init(os,ss,or,mxGetData(S),mxGetData(T));
					if (sz)
					{	init(os,ss,oi,mxGetImagData(S),mxGetData(T));
						if (tz)
						{	done(os,ss,oi,mxGetData(S),mxGetImagData(T),maddXkn);
							done(os,ss,or,mxGetImagData(S),mxGetImagData(T),msubXkn);
							break;
						}
					}
					if (tz) init(os,ss,oi,mxGetData(S),mxGetImagData(T));
					break;
				}
				fvtimes(or,oi,mxGetData(S),mxGetImagData(S),mxGetData(T),mxGetImagData(T),m,n);
			}
			break;
		}
		if (m > 0 || n > 0) mexErrMsgTxt("Incompatible dimensions.");
	}
}
