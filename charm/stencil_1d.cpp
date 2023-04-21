#include "heat1d.decl.h"

#include <fstream>
#include <filesystem>

/* readonly */ CProxy_Main mainProxy;
/* readonly */ int grid_size;
/* readonly */ int chare_grid_size;
/* readonly */ int num_chares;
/* readonly */ int total_time_steps;

/* readonly */ double k;
/* readonly */ double dt;
/* readonly */ double dx;

#define TOTAL_TIME_STEPS 100
#define LEFT 1
#define RIGHT 1

class Main : public CBase_Main
{
    double start_time;
    double total_time;

public:
    Main(CkArgMsg* m)
    {
        if (m->argc != 4)
            CkAbort("Need 3 arguments in order: [Num Chares] [Num Time Steps] [Grid Size]");
        
        num_chares = atoi(m->argv[1]);
        total_time_steps = atoi(m->argv[2]);
        grid_size = atoi(m->argv[3]);

        k = 0.4;
        dt = 1.;
        dx = 1.;

        if (grid_size % num_chares != 0)
            CkAbort("Grid Size is not a multiple of Num Chares");
        
        mainProxy = thisProxy;
        chare_grid_size = grid_size / num_chares;

        CProxy_Jacobi jacobi = CProxy_Jacobi::ckNew(num_chares);

        // Start Timer
        start_time = CkWallTimer();
        jacobi.run();
    }

    void done()
    {
        total_time = CkWallTimer() - start_time;

        ckout << "lang,nx,nt,threads,dt,dx,total time,flops" << endl;
        ckout << "charm++," << grid_size << "," << total_time_steps << "," << CkNumPes() << "," << 1. << "," << 1. << "," << total_time << ",0" << endl;

        if(!std::filesystem::exists("perfdata.csv")) {
            std::ofstream f("perfdata.csv");
            f << "lang,nx,nt,threads,dt,dx,total time,flops" << std::endl;
            f.close();
        }
        std::ofstream f("perfdata.csv",std::ios_base::app);
        f << "charm++," << grid_size << "," << total_time_steps << "," << CkNumPes() << "," << 1. << "," << 1. << "," << total_time << ",0" << std::endl;
        f.close();

        CkExit();
    }
};

class Jacobi : public CBase_Jacobi
{
    Jacobi_SDAG_CODE;

    using array1d = std::vector<double>;

public:

    array1d temperature;
    array1d new_temperature;

    // SDAG variables
    std::size_t imsg;
    std::size_t neighbors;
    std::size_t curr_time_step;
    std::size_t istart, ifinish;

    Jacobi()
    : temperature(chare_grid_size + 2)
    , new_temperature(chare_grid_size + 2)
    , imsg(0)
    , neighbors(2)
    , curr_time_step(0)
    , istart(1)
    , ifinish(chare_grid_size + 1)
    {
        for (std::size_t i = 0; i != temperature.size(); ++i)
            temperature[i] = thisIndex * chare_grid_size + i - 1;
    }

    Jacobi(CkMigrateMessage* m) {}

    void pup(PUP::er &p)
    {
        p | temperature;
        p | new_temperature;
        p | imsg;
        p | curr_time_step;
        p | istart;
        p | ifinish;
    }

    void compute()
    {
        for (std::size_t i = istart; i != ifinish; ++i)
            new_temperature[i] = temperature[i] + k * (dt / (dx * dx)) * (temperature[i + 1] + temperature[i - 1] - 2 * temperature[i]); 

        temperature.swap(new_temperature);
    }
};

#include "heat1d.def.h"