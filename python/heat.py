import asyncio
import numpy as np
import sys
import time

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



async def work(future,current,start,end):
    for i in range(start,end):
        future[i] = heat(current[idx(i, -1)],
                        current[i], current[idx(i, +1)])

async def main():
    length = int(nx / threads)
    space = [np.zeros(nx),np.zeros(nx)]
    
    for i in range(0,nx):
        space[0][i] = i

    
    for t in range(0,nt):
        current = space[t %2]
        future = space[(t+1) % 2]

        futures = []
        for p in range(0,threads):
        
            start = p * length
            end = (p+1) * length
            if p == threads-1:
                end = nx
            
            futures.append(asyncio.create_task(work(future,current,start,end)))
        await asyncio.wait(futures)
        #for f in futures:
        #    await f
         

if __name__ == "__main__":
    start_time = time.time()
    loop = asyncio.get_event_loop()
    try:
        loop.run_until_complete(main())
    finally:
        loop.close()
    print("time:",threads,time.time() - start_time,nx)
                                            
