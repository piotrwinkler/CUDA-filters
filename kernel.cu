#include <iostream>
#include <fstream>
#include <windows.h>
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <chrono>
#include <cmath>

using namespace std;
using namespace std::chrono;

struct header1
{
	char bfType[2];
	int bfSize;
	char bfReserved1[2];
	char bfReserved2[2];
	int bfOffBits;
};

struct header2
{
	int biSize;
	int biWidth;
	int biHeight;
	char biPlanes[2];
	char biBitCount[2];
	int biCompression;
	int biSizeImage;
	int biXpelsPerMeter;
	int biYpelsPerMeter;
	int biCrlUses;
	int biCrlImportant;
};

#define tablica(i,j) tablica[(i)*kol+(j)]
#define mask(i,j) mask[(i)*kol+(j)]

//Funkcja odczytujaca naglowek pliku
//==============================================================================================================================================================================
void WczytanieNagl(header1 &FileHeader11, header2 &FileHeader12, int &polozenie1)
{
	ifstream plik1("image.bmp", ios::binary);
	if (!plik1)
	{
		cout << "Blad otwarcia pliku. Koniec programu." << endl;
		exit(0);
	}

	plik1.read(reinterpret_cast<char *>(&FileHeader11.bfType), 2);
	plik1.read(reinterpret_cast<char *>(&FileHeader11.bfSize), 4);
	plik1.read(reinterpret_cast<char *>(&FileHeader11.bfReserved1), 2);
	plik1.read(reinterpret_cast<char *>(&FileHeader11.bfReserved2), 2);
	plik1.read(reinterpret_cast<char *>(&FileHeader11.bfOffBits), 4);


	plik1.read(reinterpret_cast<char *>(&FileHeader12.biSize), 4);
	plik1.read(reinterpret_cast<char *>(&FileHeader12.biWidth), 4);
	plik1.read(reinterpret_cast<char *>(&FileHeader12.biHeight), 4);
	plik1.read(reinterpret_cast<char *>(&FileHeader12.biPlanes), 2);
	plik1.read(reinterpret_cast<char *>(&FileHeader12.biBitCount), 2);
	plik1.read(reinterpret_cast<char *>(&FileHeader12.biCompression), 4);
	plik1.read(reinterpret_cast<char *>(&FileHeader12.biSizeImage), 4);
	plik1.read(reinterpret_cast<char *>(&FileHeader12.biXpelsPerMeter), 4);
	plik1.read(reinterpret_cast<char *>(&FileHeader12.biYpelsPerMeter), 4);
	plik1.read(reinterpret_cast<char *>(&FileHeader12.biCrlUses), 4);
	plik1.read(reinterpret_cast<char *>(&FileHeader12.biCrlImportant), 4);

	polozenie1 = plik1.tellg();
	//cout << polozenie1 << endl;

	//cout << FileHeader12.biWidth << endl;
	//cout << FileHeader12.biHeight << endl;
	//cout << FileHeader12.biSize << endl;

	plik1.close();

	//cout << FileHeader11.bfType << endl << FileHeader11.bfSize << endl << FileHeader11.bfReserved1 << endl << FileHeader11.bfReserved2 << endl << FileHeader11.bfOffBits << endl;
	//cout << FileHeader12.biSize << endl << FileHeader12.biWidth << endl << FileHeader12.biHeight << endl << FileHeader12.biPlanes << endl << FileHeader12.biBitCount << endl << FileHeader12.biCompression << endl << FileHeader12.biSizeImage << endl << FileHeader12.biXpelsPerMeter << endl << FileHeader12.biYpelsPerMeter << endl << FileHeader12.biCrlUses << endl << FileHeader12.biCrlImportant << endl;
}
//==============================================================================================================================================================================



//Funkcja odczytujaca dane o obrazie
//==============================================================================================================================================================================
void WczytanieObr(int polozenie1, int kol, int wier, int *tablica)
{

	ifstream plik1("image.bmp", ios::binary);
	if (!plik1)
	{
		cout << "Blad otwarcia pliku. Koniec programu." << endl;
		exit(0);
	}
	plik1.seekg(polozenie1);

	//Wype³nienie tablicy zerami w celu unikniêcia b³êdów sczytywania danych
	for (int i = 0; i < wier; i++)
	{
		for (int j = 0; j < kol; j++)
		{
			tablica(i, j) = 0;
		}
	}

	for (int i = 0; i < wier; i++)
	{
		for (int j = 0; j < kol; j++)
		{
			plik1.read(reinterpret_cast<char *>(&tablica(i,j)), 1);
		}
	}
	
	plik1.close();
}
//==============================================================================================================================================================================


//Funkcja zapisujaca dane do nowego pliku z zastosowaniem filtru dolnoprzepustowego na CPU
//==============================================================================================================================================================================
void FiltrDolCPU(header1 FileHeader11, header2 FileHeader12, int kol, int wier, int *tablica)
{
	ofstream plik("image_low_pass_filter_CPU.bmp", ios::binary);
	if (!plik)
	{
		cout << "Blad utworzenia pliku. Koniec programu." << endl;
		exit(0);
	}

	//Zapis naglowka
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfType), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfSize), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfReserved1), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfReserved2), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfOffBits), 4);


	plik.write(reinterpret_cast<char *>(&FileHeader12.biSize), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biWidth), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biHeight), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biPlanes), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biBitCount), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biCompression), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biSizeImage), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biXpelsPerMeter), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biYpelsPerMeter), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biCrlUses), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biCrlImportant), 4);

	//Zapis danych o obrazie
	auto start = high_resolution_clock::now();
	for (int i = 0; i < wier; i++)
	{
		for (int j = 0; j < kol; j++)
		{
			int mask = tablica(i, j);
			if(i == 0 || i == wier - 1 || j < 3 || j > kol - 4)
			plik.write(reinterpret_cast<char *>(&tablica(i,j)), 1);
			else
			{
				int mask = tablica(i, j) + tablica(i+1, j+3) + tablica(i-1, j-3) + tablica(i+1, j-3) + tablica(i-1, j+3) + tablica(i+1, j) + tablica(i-1, j) + tablica(i, j+3) + tablica(i, j-3);
				mask = (int)(mask / 9);
				mask = abs(mask);
				plik.write(reinterpret_cast<char *>(&mask), 1);
			}
		}
	}
	auto stop = high_resolution_clock::now();
	auto duration = duration_cast<microseconds>(stop - start);
	cout << "Czas nakladania maski filtru dolnoprzepustowego na CPU: " << duration.count() << endl << endl;

	plik.close();
}
//==============================================================================================================================================================================


//Funkcja zapisujaca dane do nowego pliku z zastosowaniem filtru gornoprzepustowego na CPU
//==============================================================================================================================================================================
void FiltrGorCPU(header1 FileHeader11, header2 FileHeader12, int kol, int wier, int *tablica)
{
	ofstream plik("image_high_pass_filter_CPU.bmp", ios::binary);
	if (!plik)
	{
		cout << "Blad utworzenia pliku. Koniec programu." << endl;
		exit(0);
	}

	//Zapis naglowka
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfType), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfSize), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfReserved1), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfReserved2), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfOffBits), 4);


	plik.write(reinterpret_cast<char *>(&FileHeader12.biSize), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biWidth), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biHeight), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biPlanes), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biBitCount), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biCompression), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biSizeImage), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biXpelsPerMeter), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biYpelsPerMeter), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biCrlUses), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biCrlImportant), 4);

	//Zapis danych o obrazie
	auto start = high_resolution_clock::now();
	for (int i = 0; i < wier; i++)
	{
		for (int j = 0; j < kol; j++)
		{
			int mask = tablica(i, j);
			if (i == 0 || i == wier - 1 || j < 3 || j > kol - 4)
				plik.write(reinterpret_cast<char *>(&tablica(i, j)), 1);
			else
			{
				//int mask = 5*tablica(i, j) - tablica(i + 1, j + 3) - tablica(i - 1, j - 3) - tablica(i + 1, j - 3) - tablica(i - 1, j + 3) - tablica(i + 1, j) - tablica(i - 1, j) - tablica(i, j + 3) - tablica(i, j - 3);
				int mask = 5 * tablica(i, j) - tablica(i + 1, j) - tablica(i - 1, j) - tablica(i, j + 3) - tablica(i, j - 3);
				mask = (int)(mask / 1);
				mask = abs(mask);
				plik.write(reinterpret_cast<char *>(&mask), 1);
			}
		}
	}
	auto stop = high_resolution_clock::now();
	auto duration = duration_cast<microseconds>(stop - start);
	cout << "Czas nakladania maski filtru gornoprzepustowego na CPU: " << duration.count() << endl << endl;

	plik.close();
}
//==============================================================================================================================================================================


//KERNEL->filtr dolnoprzepustowy
//==============================================================================================================================================================================
__global__ void FiltrDol(const int *tablica, int *mask, int kol, int wier)
{
	int ko = threadIdx.y + blockIdx.y * blockDim.y;
	int wi = threadIdx.x + blockIdx.x * blockDim.x;
	if (ko < kol && wi < wier)
	{
		if (wi == 0 || wi == wier - 1 || ko < 3 || ko > kol - 4)
			mask(wi, ko) = tablica(wi, ko);
		else
		{
			mask(wi, ko) = tablica(wi, ko) + tablica(wi + 1, ko + 3) + tablica(wi - 1, ko - 3) + tablica(wi + 1, ko - 3) + tablica(wi - 1, ko + 3) + tablica(wi + 1, ko) + tablica(wi - 1, ko) + tablica(wi, ko + 3) + tablica(wi, ko - 3);
			mask(wi, ko) = (int)(mask(wi, ko) / 9);
			mask(wi, ko) = abs(mask(wi, ko));
		}
	}
}
//==============================================================================================================================================================================


//KERNEL->filtr gornoprzepustowy
//==============================================================================================================================================================================
__global__ void FiltrGor(const int *tablica, int *mask, int kol, int wier)
{
	int ko = threadIdx.y + blockIdx.y * blockDim.y;
	int wi = threadIdx.x + blockIdx.x * blockDim.x;
	if (ko < kol && wi < wier)
	{
		if (wi == 0 || wi == wier - 1 || ko < 3 || ko > kol - 4)
			mask(wi, ko) = tablica(wi, ko);
		else
		{
			//int mask(wi, ko) = 5*tablica(wi, ko) - tablica(wi + 1, ko + 3) - tablica(wi - 1, ko - 3) - tablica(wi + 1, ko - 3) - tablica(wi - 1, ko + 3) - tablica(wi + 1, ko) - tablica(wi - 1, ko) - tablica(wi, ko + 3) - tablica(wi, ko - 3);
			mask(wi, ko) = 5 * tablica(wi, ko) - tablica(wi + 1, ko) - tablica(wi - 1, ko) - tablica(wi, ko + 3) - tablica(wi, ko - 3);
			mask(wi, ko) = (int)(mask(wi, ko) / 1);
			mask(wi, ko) = abs(mask(wi, ko));
		}
	}
}
//==============================================================================================================================================================================


//Funkcja zapisujaca dane do nowego pliku z zastosowaniem filtru dolnoprzepustowego na GPU
//==============================================================================================================================================================================
void FiltrDolGPU(header1 FileHeader11, header2 FileHeader12, int kol, int wier, int *tablica)
{
	ofstream plik("image_low_pass_filter_GPU.bmp", ios::binary);
	if (!plik)
	{
		cout << "Blad utworzenia pliku. Koniec programu." << endl;
		exit(0);
	}

	//Zapis naglowka
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfType), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfSize), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfReserved1), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfReserved2), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfOffBits), 4);


	plik.write(reinterpret_cast<char *>(&FileHeader12.biSize), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biWidth), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biHeight), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biPlanes), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biBitCount), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biCompression), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biSizeImage), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biXpelsPerMeter), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biYpelsPerMeter), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biCrlUses), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biCrlImportant), 4);

	int *mask;
	int *tab_cuda = 0, *mask_cuda = 0;

	mask = (int *)malloc(sizeof(*mask)*wier*kol);
	cudaMalloc((void**)&tab_cuda, wier*kol * sizeof(*tab_cuda));
	cudaMalloc((void**)&mask_cuda, wier*kol * sizeof(*mask_cuda));
	cudaMemcpy(tab_cuda, tablica, sizeof(*tab_cuda)*wier*kol, cudaMemcpyHostToDevice);

	dim3 blockDim(10, 10);
	dim3 gridDim(1000, 1000);

	auto start = high_resolution_clock::now();
	//==============================================================================================================================================================================
	FiltrDol << < gridDim, blockDim >> > (tab_cuda, mask_cuda, kol, wier);
	//==============================================================================================================================================================================
	auto stop = high_resolution_clock::now();
	auto duration = duration_cast<microseconds>(stop - start);
	cout << "Czas nakladania maski filtru dolnoprzepustowego na GPU: " << duration.count() << endl << endl;

	cudaMemcpy(mask, mask_cuda, wier*kol * sizeof(*mask), cudaMemcpyDeviceToHost);

	for (int i = 0; i < wier; i++)
	{
		for (int j = 0; j < kol; j++)
		{
			plik.write(reinterpret_cast<char *>(&mask(i, j)), 1);
		}
	}

	free(mask);
	cudaFree(tab_cuda);
	cudaFree(mask_cuda);

	plik.close();
}
//==============================================================================================================================================================================


//Funkcja zapisujaca dane do nowego pliku z zastosowaniem filtru gornoprzepustowego na GPU
//==============================================================================================================================================================================
void FiltrGorGPU(header1 FileHeader11, header2 FileHeader12, int kol, int wier, int *tablica)
{
	ofstream plik("image_high_pass_filter_GPU.bmp", ios::binary);
	if (!plik)
	{
		cout << "Blad utworzenia pliku. Koniec programu." << endl;
		exit(0);
	}

	//Zapis naglowka
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfType), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfSize), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfReserved1), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfReserved2), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader11.bfOffBits), 4);


	plik.write(reinterpret_cast<char *>(&FileHeader12.biSize), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biWidth), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biHeight), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biPlanes), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biBitCount), 2);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biCompression), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biSizeImage), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biXpelsPerMeter), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biYpelsPerMeter), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biCrlUses), 4);
	plik.write(reinterpret_cast<char *>(&FileHeader12.biCrlImportant), 4);

	int *mask;
	int *tab_cuda = 0, *mask_cuda = 0;

	mask = (int *)malloc(sizeof(*mask)*wier*kol);
	cudaMalloc((void**)&tab_cuda, wier*kol * sizeof(*tab_cuda));
	cudaMalloc((void**)&mask_cuda, wier*kol * sizeof(*mask_cuda));
	cudaMemcpy(tab_cuda, tablica, sizeof(*tab_cuda)*wier*kol, cudaMemcpyHostToDevice);

	dim3 blockDim(10, 10);
	dim3 gridDim(1000, 1000);

	auto start = high_resolution_clock::now();
	//==============================================================================================================================================================================
	FiltrGor << < gridDim, blockDim >> > (tab_cuda, mask_cuda, kol, wier);
	//==============================================================================================================================================================================
	auto stop = high_resolution_clock::now();
	auto duration = duration_cast<microseconds>(stop - start);
	cout << "Czas nakladania maski filtru gornoprzepustowego na GPU: " << duration.count() << endl << endl;

	cudaMemcpy(mask, mask_cuda, wier*kol * sizeof(*mask), cudaMemcpyDeviceToHost);

	for (int i = 0; i < wier; i++)
	{
		for (int j = 0; j < kol; j++)
		{
			plik.write(reinterpret_cast<char *>(&mask(i, j)), 1);
		}
	}

	free(mask);
	cudaFree(tab_cuda);
	cudaFree(mask_cuda);

	plik.close();
}
//==============================================================================================================================================================================


int main()
{
	header1 FileHeader11;
	header2 FileHeader12;
	int polozenie1;
	WczytanieNagl(FileHeader11, FileHeader12, polozenie1);

	int kol = FileHeader12.biWidth * 3;
	if(kol%4 != 0)
		kol = FileHeader12.biWidth * 3 + (4 - (FileHeader12.biWidth * 3) % 4);
	int wier = FileHeader12.biHeight;

	int *tablica;
	tablica = (int *)malloc(sizeof(*tablica)*wier*kol);
	WczytanieObr(polozenie1, kol, wier, tablica);

	FiltrDolCPU(FileHeader11, FileHeader12, kol, wier, tablica);
	FiltrDolGPU(FileHeader11, FileHeader12, kol, wier, tablica);
	FiltrGorCPU(FileHeader11, FileHeader12, kol, wier, tablica);
	FiltrGorGPU(FileHeader11, FileHeader12, kol, wier, tablica);

	free(tablica);
	
	return(0);
}
