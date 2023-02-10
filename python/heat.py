import asyncio
import numpy as np
import sys
import time
import concurrent.futures
from pypapi import events, papi_high as high

nx = int(sys.argv[3])        # number of nodes
k = 0.5        # heat transfer coefficient
dt = 1.        # time step
dx = 1.        # grid spacing
nt = int(sys.argv[2])         # number of time steps
threads = int(sys.argv[1])           # numnber of threads

def idx(i, direction):

    if i == 0 and direction == -1:
        return nx - 1
    if i == nx - 1 and direction == +1:
        return 0

    assert ((i + direction) < nx)

    return i + direction

def heat(left,middle,right):

    return middle + (k * dt / (dx * dx)) * (left - 2 * middle + right);

def work(future,current,p):
    length = int(nx / threads)
    start = p * length
    end = (p+1) * length
    
    if p == threads-1:
        end = nx

    for i in range(start,end):
        future[i] = heat(current[idx(i, -1)],
                        current[i], current[idx(i, +1)])

    return None

async def main(loop,executor):
    space = [np.zeros(nx),np.zeros(nx)]
    
    for i in range(0,nx):
        space[0][i] = i

    
    for t in range(0,nt):
        current = space[t %2]
        future = space[(t+1) % 2]

        futures = [loop.run_in_executor(executor,work,future,current,p) for p in range(threads)]
        
        for f in asyncio.as_completed(futures):
            result = await f
         

if __name__ == "__main__":
    high.start_counters([events.PAPI_FP_OPS,])
    start_time = time.time()
    executor = concurrent.futures.ProcessPoolExecutor(max_workers=10)
    loop = asyncio.get_event_loop()
    try:
        loop.run_until_complete(main(loop,executor))
    finally:
        loop.close()
        x=high.stop_counters()
    print("time:",threads,time.time() - start_time,nx,x)
                                            
