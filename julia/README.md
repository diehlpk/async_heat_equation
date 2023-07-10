# Installation
Make sure you are using the latest stable version of Julia (v1.9) (which can be installed via [`juliaup`](https://github.com/JuliaLang/juliaup)).

This code requires installing some dependencies, which can be done by opening the current folder in your terminal and running:
```bash
julia --project -e "using Pkg; Pkg.instantiate()"
```

# Running tests

## Heat

```bash
nthreads=8
timesteps=1000
nodes=1000000
julia --project --threads=$nthreads heat/heat.jl $nthreads $timesteps $nodes
```