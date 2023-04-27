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

class Main : public CBase_Main
{
    double start_time;
    double total_time;

    CProxy_Jacobi jacobi;

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
            ckout << "Grid Size is not a multiple of Num Chares. Last Chare will hold remaining grid nodes" << endl;
        
        mainProxy = thisProxy;
        chare_grid_size = grid_size / num_chares;

        ckout << "Stencil Info:" << endl;
        ckout << "[Grid Size] " << grid_size << endl;
        ckout << "[Num Time Steps] " << total_time_steps << endl;
        ckout << "[Grid Size per Thread] " << chare_grid_size << endl;

        jacobi = CProxy_Jacobi::ckNew(num_chares);
    }

    void init()
    {
        // Start Timer
        start_time = CkWallTimer();
        jacobi.start_jacobi();
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

    std::size_t local_grid_size;

    // SDAG variables
    std::size_t imsg;
    std::size_t neighbors;
    std::size_t curr_time_step;
    std::size_t istart, ifinish;

    Jacobi()
    : temperature(chare_grid_size + 2)
    , new_temperature(chare_grid_size + 2)
    , local_grid_size(chare_grid_size)
    , imsg(0)
    , neighbors(2)
    , curr_time_step(0)
    , istart(1)
    , ifinish(chare_grid_size + 1)
    {
        if (thisIndex == num_chares - 1 && grid_size % num_chares != 0) {
            local_grid_size += (grid_size % num_chares);
            temperature.resize(local_grid_size + 2);
            new_temperature.resize(local_grid_size + 2);
            ifinish = local_grid_size + 1;
        }
            
        for (std::size_t i = 0; i != temperature.size(); ++i)
            temperature[i] = thisIndex * chare_grid_size + i - 1;
        
        CkCallback cb(CkReductionTarget(Main, init), mainProxy);
        contribute(0, 0, CkReduction::nop, cb);
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

    void start_jacobi()
    {
        curr_time_step++;
        thisProxy((thisIndex - 1 + num_chares) % num_chares).send_ghost_left(curr_time_step, temperature.front());
        thisProxy((thisIndex + 1) % num_chares).send_ghost_right(curr_time_step, temperature.back());

        thisProxy.run();
    }
};

#include "heat1d.def.h"