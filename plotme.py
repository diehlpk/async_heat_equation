import csv
import os
import re
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

def fixname(s):
    while True:
        n = re.sub(r'(\d)(\d\d\d)\b',r'\1,\2',s)
        if s == n:
            return s
        s = n

for name in xdata:
    xv = np.asarray(xdata[name])
    yv = np.asarray(ydata[name])
    assert len(xv) == len(yv)
    fix = fixname(name)
    plt.semilogy(xv,yv,'o',label=fix)

    def rt(x, k, p, o, o2, o3):
        return k*(1-p + p/x + o*np.log(x) + o2*np.sqrt(x)+o3*x)
        
    if len(xv) > 3:
        try:
            bounds_upper = [np.inf, 1, 1, 1, 1]
            bounds_lower = [0 for x in bounds_upper]
            bounds = (tuple(bounds_lower), tuple(bounds_upper))
            print(bounds)
            r = cf(rt,xv,yv,maxfev=5000,bounds=bounds)
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
        plt.semilogy(xv2,yv2,'-',label='fit '+fix)
plt.legend()
plt.savefig('plot.png')
plt.show()
