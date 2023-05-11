# This file is part of Moden C++ exmaples 
# (https://github.com/diehlpk/modern-cpp-examples)
# Copyright (c) 2021 Patrick Diehl
# 
#  This program is free software: you can redistribute it and/or modify  
#  it under the terms of the GNU General Public License as published by  
#  the Free Software Foundation, version 3.
#
#  This program is distributed in the hope that it will be useful, but 
#  WITHOUT ANY WARRANTY; without even the implied warranty of 
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
#  General Public License for more details.
#
#  You should have received a copy of the GNU General Public License 
#  along with this program. If not, see <http://www.gnu.org/licenses/>.

From fedora:36

RUN dnf update -y
RUN dnf groupinstall "Development Tools" -y
RUN dnf install wget gperftools-devel g++ python golang julia swift-lang gcc gcc-c++ m4 perl python3 python3-devel bash make gawk git hwloc-devel boost-devel jemalloc-devel cmake which diffutils llvm-devel clang clang-devel python3-numpy vim  automake libtool java-latest-openjdk-devel-1:20.0.0.0.36-1.rolling.fc36.x86_64 -y

WORKDIR /

# Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y
RUN chmod 755 /root
ENV PATH="/root/.cargo/bin:${PATH}"

# HPX
ENV HPX_VER=1.8.1
RUN wget https://github.com/STEllAR-GROUP/hpx/archive/refs/tags/${HPX_VER}.tar.gz
RUN tar xzf ${HPX_VER}.tar.gz
WORKDIR hpx-${HPX_VER}
RUN mkdir build && cd build &&  cmake -DHPX_WITH_NETWORKING=OFF -DHPX_WITH_FETCH_ASIO=ON .. && make -j 2 && make install

WORKDIR /

# Chapel
ENV CHPL_VER=1.30.0
ENV CHPL_GMP=none
ENV CHPL_HOME=/chapel-${CHPL_VER}
ENV CHPL_MEM=cstdlib
ENV CHPL_HOST_MEM=cstdlib
ENV CHPL_TASKS=qthreads
ENV CHPL_COMM=none
ENV CHPL_LLVM=system
ENV CHPL_RE2=none
RUN curl -LO https://github.com/chapel-lang/chapel/releases/download/${CHPL_VER}/chapel-${CHPL_VER}.tar.gz
RUN tar xzf chapel-${CHPL_VER}.tar.gz
WORKDIR chapel-${CHPL_VER}
RUN source util/setchplenv.bash && make -j2
RUN ls -ld /chapel-${CHPL_VER}/bin/linux64-x86_64/chpl
RUN ln -s "/chapel-${CHPL_VER}/bin/linux64-x86_64/chpl" /usr/local/bin/chpl
WORKDIR /

# Charm
RUN  git clone --depth 1 https://github.com/UIUC-PPL/charm
WORKDIR charm
RUN ./build charm++ multicore-linux-x86_64 gcc --with-production

# The Repo
WORKDIR /
RUN git clone --depth 1 https://github.com/diehlpk/async_heat_equation
WORKDIR async_heat_equation
