#include "mex.h"
#include <cstdio>
#include <cstdlib>
#include "image.h"
#include "misc.h"
#include "segment-image.h"

void mexFunction(int			nlhs, 		/* number of expected outputs */
				 mxArray		*plhs[],	/* mxArray output pointer array */
				 int			nrhs, 		/* number of inputs */
				 const mxArray	*prhs[]		/* mxArray input pointer array */)
{
	// input checks
	if (nrhs != 4 || mxIsSparse(prhs[0]) || mxGetM(prhs[1])*mxGetM(prhs[1])!=1 || mxGetM(prhs[2])*mxGetM(prhs[2])!=1 || mxGetM(prhs[3])*mxGetM(prhs[3])!=1)
	{
		mexErrMsgTxt ("USAGE: [I,sigma,K,min] = segmentmex(A,T)");
	}
	const mxArray *I = prhs[0];
	
	mxClassID dataType = mxGetClassID(I);
	mwSize ndim = mxGetNumberOfDimensions(prhs[0]);
	const mwSize *dims = mxGetDimensions(prhs[0]);
	mwSize rows = dims[0];
	mwSize cols = dims[1];
	mwSize ch   = dims[2];
	int numElIm = cols*rows;
	double sigma = *mxGetPr(prhs[1]);
	double k = *mxGetPr(prhs[2]);
	double min_size = *mxGetPr(prhs[3]);
	int num_ccs; 
	image<int> *seg;
	if(ch==3) {
		image<rgb> *im = new image<rgb>(cols, rows);
		rgb *imPtr = im->data;
		unsigned char *Iptr = (unsigned char *)mxGetData(I);
		for(int y = 0; y < rows; ++y) {
			for(int x = 0; x < cols; ++x) {
				rgb pixel;
				pixel.r = Iptr[y+x*rows];
				pixel.g = Iptr[y+x*rows+numElIm];
				pixel.b = Iptr[y+x*rows+numElIm*2];
				*(imPtr++)=pixel;
			}
		}	
		seg = segment_image(im, sigma, k, min_size, &num_ccs);
		delete im;
	}
	else if(ch==5){
		image<rgbxy> *im = new image<rgbxy>(cols, rows);
		rgbxy *imPtr = im->data;
		float *Iptr = (float *)mxGetData(I);
		for(int y = 0; y < rows; ++y) {
			for(int x = 0; x < cols; ++x) {
				rgbxy pixel;
				pixel.r = Iptr[y+x*rows];
				pixel.g = Iptr[y+x*rows+numElIm];
				pixel.b = Iptr[y+x*rows+numElIm*2];
				pixel.vx = Iptr[y+x*rows+numElIm*3];
				pixel.vy = Iptr[y+x*rows+numElIm*4];
				*(imPtr++)=pixel;
			}
		}
		seg = segment_image_flow(im, sigma, k, min_size, &num_ccs);
		delete im;
	}
	
	
	int size = sizeof(unsigned int);
	if(sizeof(unsigned int)==4)
		plhs[0] = mxCreateNumericArray(ndim-1, dims, mxUINT32_CLASS, mxREAL);
	else if(sizeof(unsigned int)==2)
		plhs[0] = mxCreateNumericArray(ndim-1, dims, mxUINT16_CLASS, mxREAL);
	unsigned int *outPtr = (unsigned int *)mxGetData(plhs[0]);
	int *segPtr = seg->data;
	for(int y = 0; y < rows; ++y)
		for(int x = 0; x < cols; ++x)
			outPtr[x*rows+y] = *(segPtr++);

	delete seg;
}