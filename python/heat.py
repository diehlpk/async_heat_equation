import asyncio
import numpy as np

nx = 100002        # number of nodes
k = 0.5        # heat transfer coefficient
dt = 1.        # time step
dx = 1.        # grid spacing
nt = 1000         # number of time steps
threads = 1           # numnber of threads

def idx(i, dir):

    if i == 0 and dir == -1:
        return nx - 1
    if i == nx - 1 and dir == +1:
        return 0

    assert ((i + dir) < nx)

    return i + dir



def heat(left,middle,right):

    return middle + (k * dt / (dx * dx)) * (left - 2 * middle + right);



async def work(next,current,start,end):

    for i in range(start,end):
        next[i] = heat(current[idx(i, -1)],
                        current[i], current[idx(i, +1)])

async def main():
 
    space = np.array([np.zeros(nx),np.zeros(nx)])
    length = int(nx / threads)


    for i in range(0,nx):
        space[0][i] = i

    for t in range(0,nt):
        current = space[t %2]
        next = space[(t+1) % 2]

        futures = []
        for p in range(0,threads):
        
            start = p * length
            end = (p+1) * length
            if p == threads-1:
                end = nx
            futures.append(loop.create_task(work(next,current,start,end)))

        await asyncio.wait(futures)                                    

if __name__ == "__main__":
    loop = asyncio.new_event_loop();
    asyncio.set_event_loop(loop)
    try:
        asyncio.run(main(loop=loop))
    except:
        pass
                                            
