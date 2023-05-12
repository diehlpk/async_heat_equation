#  Copyright (c) 2023 AUTHORS
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. (See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
import csv
import os
import re
#from math import round
import sys
import numpy
from matplotlib.lines import Line2D

if len(sys.argv)==2:
    file='-'+sys.argv[1]
else:
    file=""


if "DISPLAY" not in os.environ:
    os.environ["DISPLAY"] = ":0"

xdata = {}
ydata = {}

name_to_nx = {}
name_to_nt = {}

with open('perfdata'+file+'.csv','r',newline='') as cfd:
    skip = True
    for row in csv.reader(cfd):
        if skip:
            skip = False
            continue
        #name = "%s-%d" % (row[0], int(row[1]))
        name = row[0]
        nx = row[1]
        nt = row[2]
        if name in name_to_nt:
            if name_to_nt[name] != nt:
                print("WARNING: Multiple values of nt were used")
        else:
            name_to_nt[name] = nt
        if name in name_to_nx:
            if name_to_nx[name] != nx:
                print("WARNING: Multiple values of nx were used")
        else:
            name_to_nx[name] = nx
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

symbols = {
    "java" : "D",
    "c++" : "8",
    "cxx" : "8",
    "charm++" : "x",
    "hpx" : "+",
    "julia" : "v",
    "python" : "*",
    "swift" : "^",
    "chapel" : ">",
    "chapelng" : "<",
    "go" : "s",
    "rust" : "p",
    "heat" : "x",
    "heat_ghosts" : "p"
}

colors = {
    "java" : "darkgray",
    "c++" : "dimgray",
    "cxx" : "dimgray",
    "charm++" : "gray",
    "hpx" : "black",
    "julia" : "black",
    "python" : "black",
    "swift" : "dimgray",
    "chapel" : "gray",
    "chapelng" : "darkgray",
    "go" : "silver",
    "rust" : "black",
    "heat" : "black",
    "heat_ghosts" : "gray"
}

lines = {
    "java" : "-",
    "c++" : "--",
    "cxx" : ":",
    "charm++" : "-",
    "hpx" : "--",
    "julia" : ":",
    "python" : "-",
    "swift" : "--",
    "chapel" : ":",
    "chapelng" : "-",
    "go" : "--",
    "rust" : ":",
    "heat" : "-",
    "heat_ghosts" : "--"
}

lineLabels = []
labels = []

for name in xdata:
    xv = np.asarray(xdata[name])
    yv = np.asarray(ydata[name])
    assert len(xv) == len(yv)
    fix = fixname(name)
    symbol = symbols[name]
    color = colors[name]
    labels.append(fix)
    lineLabels.append(Line2D([0], [0], color=color, linewidth=3, linestyle='--', marker=symbol))
    p = plt.semilogy(xv,yv,symbol,color=color)

    def rt(x, k, p, o, o2, o3):
        return k*(1-p + p/x + o*np.log(x) + o2*np.sqrt(x)+o3*x)
        
    if len(xv) > 3:
        try:
            bounds_upper = [np.inf, 1, 1, 1, 1]
            bounds_lower = [0 for x in bounds_upper]
            bounds = (tuple(bounds_lower), tuple(bounds_upper))
            r  = cf(rt,xv,yv,maxfev=5000,bounds=bounds)
        except Exception as e:
            print("Could not fit curve for:",name,e)
            continue
        k=r[0][0]
        pbar=r[0][1]
        o=r[0][2]
        o2=r[0][3]
        o3=r[0][4]
        print("For ",name,": Parallel=","%.8g" % pbar," using ",len(xv)," run data pts.",sep='')
        overheads = 0
        if o > 1e-14:
            print("   Overhead log(N)=%.8g:" % o),
            overheads += 1
        if o2 > 1e-14:
            print("   Overhead sqrt(N)=%.8g:" % o2),
            overheads += 1
        if o3 > 1e-14:
            print("   Overhead N=%.8g:" % o3),
            overheads += 1
        if overheads == 0:
            print("   No appreciable overheads")
        corr_matrix = numpy.corrcoef(xv,yv)
        corr = corr_matrix[0,1]
        print("r2 = ",corr**2)
        print()
        xv2 = np.asarray(range(1,round(1+max(xdata[name]))))
        yv2 = rt(xv2,*r[0])
        line = lines[name]
        plt.semilogy(xv2,yv2,line,color=color)
        #plt.semilogy(xv2,yv2,'-',label='fit '+fix,color=color)
plt.legend(lineLabels,labels,ncol=4,shadow=True,fancybox=True,loc='upper center', bbox_to_anchor=(0.5, -0.15))
ax = plt.gca()
#ax.legend(loc='upper center', bbox_to_anchor=(0.5, -0.15),
#          fancybox=True, shadow=True, ncol=4)
plt.grid()
plt.xlabel("#cores")
plt.ylabel("Time [s]")
plt.title("nx="+nx+" and nt="+nt)
plt.savefig('plot'+file+'.pdf',bbox_inches='tight')
plt.savefig('plot'+file+'.png',bbox_inches='tight')
plt.tight_layout()
print("Saving to plotme.png")
plt.savefig("plotme.png")
plt.show()
