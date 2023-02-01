#This file is part of the Monte carlo code exmaples.
#Copyright (c) 2021 Patrick Diehl
# 
#This program is free software: you can redistribute it and/or modify  
#it under the terms of the GNU General Public License as published by  
#the Free Software Foundation, version 3.
#
#This program is distributed in the hope that it will be useful, but 
#WITHOUT ANY WARRANTY; without even the implied warranty of 
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
#General Public License for more details.
#
#You should have received a copy of the GNU General Public License 
#along with this program. If not, see <http://www.gnu.org/licenses/>.
import random

ncount = 0.0

# Ask the user for the nummber of iterations
end = int(input("Please enter the number of iterations:"))

#  Loop over the iterations
for _ in range(end):
    xVar = random.uniform(0,1)
    yVar = random.uniform(0,1)

    if xVar * xVar + yVar * yVar <= 1:
        ncount +=1 

# Compute the final result
pi = 4.0 * ncount / end

# Print the final result
print(" Pi is equal to " + str(pi) + " after " + str(end) + " iterations")







