/*
 * CitcomCU is a Finite Element Code that solves for thermochemical
 * convection within a three dimensional domain appropriate for convection
 * within the Earth's mantle. Cartesian and regional-spherical geometries
 * are implemented. See the file README contained with this distribution
 * for further details.
 * 
 * Copyright (C) 1994-2005 California Institute of Technology
 * Copyright (C) 2000-2005 The University of Colorado
 *
 * Authors: Louis Moresi, Shijie Zhong, and Michael Gurnis
 *
 * For questions or comments regarding this software, you may contact
 *
 *     Luis Armendariz <luis@geodynamics.org>
 *     http://geodynamics.org
 *     Computational Infrastructure for Geodynamics (CIG)
 *     California Institute of Technology
 *     2750 East Washington Blvd, Suite 210
 *     Pasadena, CA 91007
 *
 * This program is free software; you can redistribute it and/or modify 
 * it under the terms of the GNU General Public License as published by 
 * the Free Software Foundation, either version 2 of the License, or any
 * later version.
 *
 * This program is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of 
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License 
 * along with this program; if not, write to the Free Software 
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */

/*  Here are the routines which process the results of each buoyancy solution, and call
    any relevant output routines. Much of the information has probably been output along
    with the velocity field. (So the velocity vectors and other data are fully in sync).
    However, heat fluxes and temperature averages are calculated here (even when they
    get output the next time around the velocity solver);
    */

extern "C"{

	#include <math.h>
	#include <malloc.h>
	#include <sys/time.h>
	#include <sys/types.h>
	#include <stdlib.h>				/* for "system" command */
	#include <cuda_runtime.h>

	#include "element_definitions.h"
	#include "global_defs.h"

}


extern "C"{
	void process_temp_field(struct All_variables *E, int ii)
	{
		if(((ii % E->control.record_every) == 0))
		{
			heat_flux(E);
			/* output_temp(E,ii); */
		}
		return;
	}

// CUDA内核函数
__global__ void heat_flux_kernel(float* d_VZ, float* d_T, float* d_N_vpt, float* d_Have_T, float* d_gNX_vpt, int* d_ien_node, int e, int vpts, int ends, float* d_u, float* d_T1, float* d_dTdz,int nodez) {
    int j = threadIdx.x + blockIdx.x * blockDim.x;
    if (j <= ends) {
        int lnode = (d_ien_node[j] - 1) % nodez + 1;

        int gnvindex = GNVINDEX(j, threadIdx.y);
        int gnvxindex = GNVXINDEX(2, j, threadIdx.y);

        // 使用原子操作确保多线程间的累积操作正确无误
        atomicAdd(&d_u[threadIdx.y], d_VZ[j] * d_N_vpt[gnvindex]);
        atomicAdd(&d_T[threadIdx.y], d_T[d_ien_node[j]] * d_N_vpt[gnvindex]);
        atomicAdd(&d_T1[threadIdx.y], (d_T[d_ien_node[j]] - d_Have_T[lnode]) * d_N_vpt[gnvindex]);
        atomicAdd(&d_dTdz[threadIdx.y], d_T[d_ien_node[j]] * d_gNX_vpt[gnvxindex]);
    }
}

void heat_flux(struct All_variables *E)
{
	int e, ee, i, j, node, lnode;
	static float *flux;
	static float *inp, *outp;
	static int been_here = 0;
	//double T1[9], VZ[9], u[9], T[9], dTdz[9], area, uT, uT_adv, uT_adv_s;
	double T1[9], VZ[9], u[9], T[9], dTdz[9], uT, uT_adv, uT_adv_s;
	double diff, tempb, tempt, hfb, hft, areab, areat;

	//struct Shape_function GN;
	//struct Shape_function_dA dOmega;
	//struct Shape_function_dx GNx;

	const int dims = E->mesh.nsd;
	//const int dofs = E->mesh.dof;
	const int vpts = vpoints[dims];
	//const int ppts = ppoints[dims];
	const int ends = enodes[dims];
	const int nno = E->lmesh.nno;
	const int lev = E->mesh.levmax;

	if(been_here == 0)
	{
		inp = (float *)malloc((6) * sizeof(float));
		outp = (float *)malloc((6) * sizeof(float));
		flux = (float *)malloc((nno + 3) * sizeof(float));
		been_here = 1;
	}

	return_horiz_ave(E, E->T, E->Have.T);


	for(i = 1; i <= nno; i++)
	{
		flux[i] = 0.0;
		E->heatflux[i] = 0.0;
		E->heatflux_adv[i] = 0.0;
	}

	for(e = 1; e <= E->lmesh.nel; e++)
	{
		ee = (e - 1) % E->lmesh.elz + 1;
		diff = (E->diffusivity[ee] + E->diffusivity[ee + 1]) * 0.5;

		for(j = 1; j <= ends; j++)
			VZ[j] = E->V[3][E->ien[e].node[j]];

		uT = 0.0;
		uT_adv = 0.0;
		uT_adv_s = 0.0;
		for(i = 1; i <= vpts; i++)
		{
			u[i] = 0.0;
			T[i] = 0.0;
			dTdz[i] = 0.0;
			T1[i] = 0.0;
			// for(j = 1; j <= ends; j++)
			// {

			// 	lnode = (E->ien[e].node[j] - 1) % E->lmesh.noz + 1;

			// 	u[i] += VZ[j] * E->N.vpt[GNVINDEX(j, i)];
			// 	T[i] += E->T[E->ien[e].node[j]] * E->N.vpt[GNVINDEX(j, i)];
			// 	T1[i] += (E->T[E->ien[e].node[j]] - E->Have.T[lnode]) * E->N.vpt[GNVINDEX(j, i)];
			// 	dTdz[i] = dTdz[i] + E->T[E->ien[e].node[j]] * E->gNX[e].vpt[GNVXINDEX(2, j, i)];
			// }

			// 设备端内存分配
float* d_VZ;
float* d_T;
float* d_N_vpt;
float* d_gNX_vpt;
float* d_Have_T;
int* d_ien_node;

// // 主机端数据复制至设备端
// cudaMalloc((void**)&d_VZ, sizeof(float) * ends);
// cudaMemcpy(d_VZ, VZ, sizeof(float) * ends, cudaMemcpyHostToDevice);

// cudaMalloc((void**)&d_T, sizeof(float) * vpts);
// cudaMemcpy(d_T, E->T, sizeof(float) * vpts, cudaMemcpyHostToDevice);

// cudaMalloc((void**)&d_N_vpt, sizeof(float) * vpts);
// cudaMemcpy(d_N_vpt, E->N.vpt, sizeof(float) * vpts, cudaMemcpyHostToDevice);

// cudaMalloc((void**)&d_Have_T, sizeof(float) * E->lmesh.noz);
// cudaMemcpy(d_Have_T, E->Have.T, sizeof(float) * E->lmesh.noz, cudaMemcpyHostToDevice);

// cudaMalloc((void**)&d_gNX_vpt, sizeof(float) * vpts);
// cudaMemcpy(d_gNX_vpt, E->gNX[e].vpt, sizeof(float) * vpts, cudaMemcpyHostToDevice);

// cudaMalloc((void**)&d_ien_node, sizeof(int) * ends);
// cudaMemcpy(d_ien_node, E->ien[e].node, sizeof(int) * ends, cudaMemcpyHostToDevice);

// 创建CUDA流
cudaStream_t stream;
cudaStreamCreate(&stream);
// 异步主机端数据复制至设备端
cudaMallocAsync((void**)&d_VZ, sizeof(float) * ends, stream);
cudaMemcpyAsync(d_VZ, VZ, sizeof(float) * ends, cudaMemcpyHostToDevice, stream);

cudaMallocAsync((void**)&d_T, sizeof(float) * vpts, stream);
cudaMemcpyAsync(d_T, E->T, sizeof(float) * vpts, cudaMemcpyHostToDevice, stream);

cudaMallocAsync((void**)&d_N_vpt, sizeof(float) * vpts, stream);
cudaMemcpyAsync(d_N_vpt, E->N.vpt, sizeof(float) * vpts, cudaMemcpyHostToDevice, stream);

cudaMallocAsync((void**)&d_Have_T, sizeof(float) * E->lmesh.noz, stream);
cudaMemcpyAsync(d_Have_T, E->Have.T, sizeof(float) * E->lmesh.noz, cudaMemcpyHostToDevice, stream);

cudaMallocAsync((void**)&d_gNX_vpt, sizeof(float) * vpts, stream);
cudaMemcpyAsync(d_gNX_vpt, E->gNX[e].vpt, sizeof(float) * vpts, cudaMemcpyHostToDevice, stream);

cudaMallocAsync((void**)&d_ien_node, sizeof(int) * ends, stream);
cudaMemcpyAsync(d_ien_node, E->ien[e].node, sizeof(int) * ends, cudaMemcpyHostToDevice, stream);

float* d_u;
float* d_T1;
float* d_dTdz;

cudaMalloc((void**)&d_u, sizeof(float) * vpts);
cudaMalloc((void**)&d_T1, sizeof(float) * vpts);
cudaMalloc((void**)&d_dTdz, sizeof(float) * vpts);
// cudaMemset(d_u, 0, sizeof(float) * vpts);
// cudaMemset(d_T1, 0, sizeof(float) * vpts);
// cudaMemset(d_dTdz, 0, sizeof(float) * vpts);
cudaMemsetAsync(d_u, 0, sizeof(float) * vpts, stream);
cudaMemsetAsync(d_T1, 0, sizeof(float) * vpts, stream);
cudaMemsetAsync(d_dTdz, 0, sizeof(float) * vpts, stream);

// 等待所有异步操作完成
cudaStreamSynchronize(stream);

// 启动CUDA内核函数
int threadsPerBlock = 256; // 可根据实际情况调整
int blocksPerGrid = (ends + threadsPerBlock - 1) / threadsPerBlock;
dim3 block(threadsPerBlock, 1);
dim3 grid(blocksPerGrid);

// // 创建CUDA流
// cudaStream_t stream;
// cudaStreamCreate(&stream);

// 启动CUDA内核函数（在同一个流上）
heat_flux_kernel<<<grid, block, 0, stream>>>(d_VZ, d_T, d_N_vpt, d_Have_T, d_gNX_vpt, d_ien_node, e, vpts, ends, d_u, d_T1, d_dTdz, E->lmesh.noz);

// 异步等待CUDA内核执行完毕并同步流
cudaStreamSynchronize(stream);

// 如果需要，将结果从设备内存异步复制回主机内存
cudaMemcpyAsync(u, d_u, sizeof(float) * vpts, cudaMemcpyDeviceToHost, stream);
cudaMemcpyAsync(T1, d_T1, sizeof(float) * vpts, cudaMemcpyDeviceToHost, stream);
cudaMemcpyAsync(dTdz, d_dTdz, sizeof(float) * vpts, cudaMemcpyDeviceToHost, stream);

// 确保所有异步操作完成
cudaStreamSynchronize(stream);

// 清理CUDA流
cudaStreamDestroy(stream);


// heat_flux_kernel<<<grid, block>>>(d_VZ, d_T, d_N_vpt, d_Have_T, d_gNX_vpt, d_ien_node, e, vpts, ends, d_u, d_T1, d_dTdz,E->lmesh.noz);

// // 确保CUDA内核执行完毕
// cudaDeviceSynchronize();

// // 如果需要，将结果从设备内存复制回主机内存
// cudaMemcpy(u, d_u, sizeof(float) * vpts, cudaMemcpyDeviceToHost);
// cudaMemcpy(T1, d_T1, sizeof(float) * vpts, cudaMemcpyDeviceToHost);
// cudaMemcpy(dTdz, d_dTdz, sizeof(float) * vpts, cudaMemcpyDeviceToHost);

			uT = uT + (u[i] * T[i] - diff * dTdz[i]) * E->gDA[e].vpt[i];
			uT_adv = uT_adv + u[i] * T1[i] * E->gDA[e].vpt[i];
			uT_adv_s = uT_adv_s + u[i] * fabs(T1[i]) * E->gDA[e].vpt[i];
		}

		uT /= E->eco[e].area;
		uT_adv /= E->eco[e].area;
		uT_adv_s /= E->eco[e].area;

		for(j = 1; j <= ends; j++)
		{
			E->heatflux[E->ien[e].node[j]] += E->TWW[E->mesh.levmax][e].node[j] * uT;
			E->heatflux_adv[E->ien[e].node[j]] += E->TWW[E->mesh.levmax][e].node[j] * uT_adv;
			flux[E->ien[e].node[j]] += E->TWW[E->mesh.levmax][e].node[j] * uT_adv_s;
		}
	}							/* end of e */

	exchange_node_f20(E, flux, lev);
	exchange_node_f20(E, E->heatflux, lev);
	exchange_node_f20(E, E->heatflux_adv, lev);

	for(i = 1; i <= nno; i++)
	{
		flux[i] = flux[i] * E->Mass[i];
		E->heatflux[i] = E->heatflux[i] * E->Mass[i];
		E->heatflux_adv[i] = E->heatflux_adv[i] * E->Mass[i];
	}

	for(i = 1; i <= E->lmesh.nsf; i++)
	{
		node = E->surf_node[i];
		E->slice.shflux[i] = 2 * E->heatflux[node] - E->heatflux[node - 1];
		E->slice.bhflux[i] = 2 * E->heatflux[node - E->lmesh.noz + 1] - E->heatflux[node - E->lmesh.noz + 2];
		E->heatflux[node] = E->slice.shflux[i];
		E->heatflux[node - E->lmesh.noz + 1] = E->slice.bhflux[i];
	}

	areat = areab = hft = hfb = 0.0;

	for(i = 1; i <= E->lmesh.snel; i++)
	{
		tempb = tempt = 0.0;
		for(j = 1; j <= enodes[dims - 1]; j++)
		{
			tempb += E->slice.bhflux[E->sien[i].node[j]];
			tempt += E->slice.shflux[E->sien[i].node[j]];
		}
		e = (i - 1) * E->lmesh.elz + 1;
		hfb += tempb * E->eco[e].area;
		areab += E->eco[e].area;
		e = i * E->lmesh.elz;
		hft += tempt * E->eco[e].area;
		areat += E->eco[e].area;
	}

	inp[0] = hfb;
	inp[1] = areab;
	inp[2] = hft;
	inp[3] = areat;

	return_horiz_sum(E, inp, outp, 4);

	E->slice.Nub = outp[0] / (outp[1] * enodes[dims - 1]);
	E->slice.Nut = outp[2] / (outp[3] * enodes[dims - 1]);

	return_horiz_ave(E, E->heatflux, E->Have.Rho);
	return_horiz_ave(E, E->heatflux_adv, E->Have.F);
	return_horiz_ave(E, flux, E->Have.f);

	for(i = 1; i <= nno; i++)
		E->heatflux[i] = flux[i];

	return;
}
}
/* ===================
    GPU caculate  
   =================== */

__global__ void computeValues(float *VZ, float *u, float *T, float *dTdz, float *ppt, int *node, float *E_T, float *gNX, int ends, int ppts, int e) {
    int i = blockIdx.x * blockDim.x + threadIdx.x + 1;
    if (i <= ppts) {
        u[i] = 0.0;
        T[i] = 0.0;
        dTdz[i] = 0.0;

        for (int j = 1; j <= ends; j++) {
            u[i] += VZ[j] * ppt[GNPINDEX(j, i)];
            T[i] += E_T[node[j]] * ppt[GNPINDEX(j, i)];
            dTdz[i] += -E_T[node[j]] * gNX[GNPXINDEX(2, j, i)];
        }
    }
}


extern "C"{

/* ===================
    Surface heat flux  
   =================== */
void heat_flux1(struct All_variables *E)
{
	//int e, i, j, node, lnode;
	int e, i, j;
	float *mass, *flux, *SU, *RU, *inp, *outp;
	float VZ[9], u[9], T[9], dTdz[9], area, uT;
	double tempb, tempt, hfb, hft, areab, areat;

	//struct Shape_function GN;
	//struct Shape_function_dA dOmega;
	//struct Shape_function_dx GNx;

	const int dims = E->mesh.nsd;
	//const int dofs = E->mesh.dof;
	//const int vpts = vpoints[dims];
	const int ppts = ppoints[dims];
	const int ends = enodes[dims];
	const int nno = E->lmesh.nno;
	//const int lev = E->mesh.levmax;

	mass = (float *)malloc((1 + nno) * sizeof(float));
	flux = (float *)malloc((1 + nno) * sizeof(float));
	RU = (float *)malloc((1 + E->lmesh.nsf) * sizeof(float));
	SU = (float *)malloc((1 + E->lmesh.nsf) * sizeof(float));
	inp = (float *)malloc((6) * sizeof(float));
	outp = (float *)malloc((6) * sizeof(float));

	for(i = 1; i <= nno; i++)
	{
		mass[i] = 0.0;
		flux[i] = 0.0;
	}

	for(e = 1; e <= E->lmesh.nel; e++)
	{

		for(j = 1; j <= ends; j++)
			VZ[j] = E->V[3][E->ien[e].node[j]];

		for(i = 1; i <= ppts; i++)
		{
			u[i] = 0.0;
			T[i] = 0.0;
			dTdz[i] = 0.0;
			for(j = 1; j <= ends; j++)
			{
				u[i] += VZ[j] * E->N.ppt[GNPINDEX(j, i)];
				T[i] += E->T[E->ien[e].node[j]] * E->N.ppt[GNPINDEX(j, i)];
				dTdz[i] += -E->T[E->ien[e].node[j]] * E->gNX[e].ppt[GNPXINDEX(2, j, i)];
			}
		}

		uT = 0.0;
		area = 0.0;
		for(i = 1; i <= ppts; i++)
		{
			uT += u[i] * T[i] * E->gDA[e].ppt[i] + dTdz[i] * E->gDA[e].ppt[i];
			area += E->gDA[e].ppt[i];
		}

		uT /= area;
		for(j = 1; j <= ends; j++)
		{
			flux[E->ien[e].node[j]] += uT * E->gDA[e].ppt[1];
			mass[E->ien[e].node[j]] += E->gDA[e].ppt[1];
		}
	}							/* end of e */

	for(i = 1; i <= E->lmesh.nsf; i++)
	{
		RU[i] = flux[E->surf_node[i]];
		SU[i] = mass[E->surf_node[i]];
		flux[E->surf_node[i]] = RU[i];
		mass[E->surf_node[i]] = SU[i];
		RU[i] = flux[E->surf_node[i] + 1];
		SU[i] = mass[E->surf_node[i] + 1];
		flux[E->surf_node[i] + 1] = RU[i];
		mass[E->surf_node[i] + 1] = SU[i];
	}
	for(i = 1; i <= E->lmesh.nsf; i++)
		E->slice.shflux[i] = -(2 * flux[E->surf_node[i]] / mass[E->surf_node[i]] - flux[E->surf_node[i] + 1] / mass[E->surf_node[i] + 1]);

	for(i = 1; i <= E->lmesh.nsf; i++)
	{
		RU[i] = flux[E->surf_node[i] + E->lmesh.noz - 1];
		SU[i] = mass[E->surf_node[i] + E->lmesh.noz - 1];
		flux[E->surf_node[i] + E->lmesh.noz - 1] = RU[i];
		mass[E->surf_node[i] + E->lmesh.noz - 1] = SU[i];
		RU[i] = flux[E->surf_node[i] + E->lmesh.noz - 2];
		SU[i] = mass[E->surf_node[i] + E->lmesh.noz - 2];
		flux[E->surf_node[i] + E->lmesh.noz - 2] = RU[i];
		mass[E->surf_node[i] + E->lmesh.noz - 2] = SU[i];
	}
	for(i = 1; i <= E->lmesh.nsf; i++)
		E->slice.bhflux[i] = -(2 * flux[E->surf_node[i] + E->lmesh.noz - 1] / mass[E->surf_node[i] + E->lmesh.noz - 1] - flux[E->surf_node[i] + E->lmesh.noz - 2] / mass[E->surf_node[i] + E->lmesh.noz - 2]);

	areat = areab = hft = hfb = 0.0;

	for(i = 1; i <= E->lmesh.snel; i++)
	{
		tempb = tempt = 0.0;
		for(j = 1; j <= enodes[dims - 1]; j++)
		{
			tempb += E->slice.bhflux[E->sien[i].node[j]];
			tempt += E->slice.shflux[E->sien[i].node[j]];
		}
		e = i * E->lmesh.elz;
		hfb += tempb * E->eco[e].area;
		areab += E->eco[e].area;
		e = (i - 1) * E->lmesh.elz + 1;
		hft += tempt * E->eco[e].area;
		areat += E->eco[e].area;
	}

	inp[0] = hfb;
	inp[1] = areab;
	inp[2] = hft;
	inp[3] = areat;

	return_horiz_sum(E, inp, outp, 4);


	E->slice.Nub = outp[0] / (outp[1] * enodes[dims - 1]);
	E->slice.Nut = outp[2] / (outp[3] * enodes[dims - 1]);


	free((void *)flux);
	free((void *)mass);
	free((void *)RU);
	free((void *)SU);

	return;
}


void plume_buoyancy_flux(struct All_variables *E)
{
	//int d, nint, el, e, i, j, k, node, lnode[5];
	int d, nint, el, i, j, k, lnode[5];
	//float *mass, *flux, *SU, *RU, *inp, *outp;
	float *inp, *outp;
	//float VZ[9], u[9], T[9], dTdz[9], area, uT;
	float area, uT;

	struct Shape_function1 M;
	struct Shape_function1_dA dGamma;

	//const int dims = E->mesh.nsd;
	//const int dofs = E->mesh.dof;
	//const int vpts = vpoints[dims];
	//const int ppts = ppoints[dims];
	//const int ends = enodes[dims];
	//const int nno = E->lmesh.nno;
	const int noz = E->lmesh.noz;
	//const int noy = E->lmesh.noy;
	const int nox = E->lmesh.nox;
	const int elz = E->lmesh.elz;
	const int ely = E->lmesh.ely;
	const int elx = E->lmesh.elx;
	//const int lev = E->mesh.levmax;

	inp = (float *)malloc((6) * sizeof(float));
	outp = (float *)malloc((6) * sizeof(float));

	i = elz;
	uT = 0.0;
	area = 0.0;
	for(j = 1; j <= elx; j++)
		for(k = 1; k <= ely; k++)
		{
			el = i + (j - 1) * elz + (k - 1) * elx * elz;

			get_global_1d_shape_fn(E, el, &M, &dGamma, 0);

			lnode[1] = 1 + i + (j - 1) * noz + (k - 1) * nox * noz;
			lnode[2] = 1 + i + j * noz + (k - 1) * nox * noz;
			lnode[3] = 1 + i + j * noz + k * nox * noz;
			lnode[4] = 1 + i + (j - 1) * noz + k * nox * noz;

			for(d = 1; d <= onedvpoints[E->mesh.nsd]; d++)
				for(nint = 1; nint <= onedvpoints[E->mesh.nsd]; nint++)
				{
					uT += E->V[2][lnode[d]] * (E->T[lnode[d]] - 1.0) * E->M.vpt[GMVINDEX(d, nint)] * dGamma.vpt[GMVGAMMA(1, nint)];
					area += E->M.vpt[GMVINDEX(d, nint)] * dGamma.vpt[GMVGAMMA(1, nint)];
				}

		}						/* end of e */

	inp[0] = uT;
	inp[1] = area;

	return_horiz_sum(E, inp, outp, 1);


	E->data.buoy_flux = outp[0];

	return;
}
}
