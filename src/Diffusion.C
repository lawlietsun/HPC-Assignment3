#include "Diffusion.h"

#include "DiffusionCuda.h"
#include "ExplicitScheme.h"

#include <iostream>
#include <cstdlib>
#include <cmath>

Diffusion::Diffusion(const InputFile* input, Mesh* m) :
    mesh(m) 
{

    std::string scheme_str = input->getString("scheme", "explicit");

    if(scheme_str.compare("explicit") == 0) {
        scheme = new ExplicitScheme(input, mesh);
    } else {
        std::cerr << "Error: unknown scheme \"" << scheme_str << "\"" << std::endl;
        exit(1);
    }

    subregion = input->getDoubleList("subregion", std::vector<double>());

    if (subregion.size() != 0 && subregion.size() != 4) {
        std::cerr << "Error:  region must have 4 entries (xmin, ymin, xmax, ymax)" << std::endl;
        exit(1);
    }

    init();
}

Diffusion::~Diffusion()
{
    delete scheme;
}

void Diffusion::init()
{
    double* u0 = mesh->getU0();

    int x_min = mesh->getMin()[0];
    int x_max = mesh->getMax()[0];
    int y_min = mesh->getMin()[1]; 
    int y_max = mesh->getMax()[1]; 

    double* cellx = mesh->getCellX();
    double* celly = mesh->getCellY();

    int nx = mesh->getNx()[0]+2;

    if(!subregion.empty()) {
      int subregion_xmin = floor((subregion[0] - cellx[0])/mesh->getDx()[0]);
      int subregion_xmax = floor((subregion[2] - cellx[0])/mesh->getDx()[0]);
      int subregion_ymin = floor((subregion[1] - celly[0])/mesh->getDx()[1]);
      int subregion_ymax = floor((subregion[3] - celly[0])/mesh->getDx()[1]);

      initialiseCudaKernel(
          u0,
          x_min,
          x_max,
          y_min,
          y_max,
          nx,
          subregion_xmin,
          subregion_xmax,
          subregion_ymin,
          subregion_ymax);
    } else {
      initialiseCudaKernel(
          u0,
          x_min,
          x_max,
          y_min,
          y_max,
          nx);
    }

    scheme->init();
}

void Diffusion::doCycle(const double dt)
{
    scheme->doAdvance(dt);
}
