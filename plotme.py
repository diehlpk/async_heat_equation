import csv
import os
#from math import round

if "DISPLAY" not in os.environ:
    os.environ["DISPLAY"] = ":0"

xdata = {}
ydata = {}

with open('perfdata.csv','r',newline='') as cfd:
    skip = True
    for row in csv.reader(cfd):
        if skip:
            skip = False
            continue
        name = "%s-%d" % (row[0], int(row[1]))
        if name not in xdata:
            xdata[name] = []
            ydata[name] = []
        nthreads = float(row[3])
        xdata[name] += [nthreads]
        ydata[name] += [float(row[6])]

import matplotlib.pyplot as plt
import numpy as np
from scipy.optimize import curve_fit as cf

for name in xdata:
    xv = np.asarray(xdata[name])
    yv = np.asarray(ydata[name])
    assert len(xv) == len(yv)
    plt.semilogy(xv,yv,'o',label=name)

    def rt(x, k, p, o, o2, o3):
        return k*(1-p + p/x + o*np.log(x) + o2*np.sqrt(x)+o3*x)
        
    if len(xv) > 3:
        try:
            r = cf(rt,xv,yv,maxfev=5000,p0=(1,1,0,0,0),bounds=((0,0,0,0,0),(np.inf,1,1,1,1)))
        except Exception as e:
            print("Could not fit curve for:",name,e)
            continue
        k=r[0][0]
        par=r[0][1]
        o=r[0][2]
        print("For ",name,": Parallel=","%.2g" % par," and Overhead=","%.2g" % o," using ",len(xv)," data pts.",sep='')
        print(*r[0])
        xv2 = np.asarray(range(1,round(1+max(xdata[name]))))
        yv2 = rt(xv2,*r[0])
        plt.semilogy(xv2,yv2,'-',label='fit '+name)
plt.legend()
plt.show()
