TARGETS = go/heat/main \
	chapel/heat/heat chapel/heat/heat_ghosts \
	cxx/heat/heat_ghosts \
	rust/heat/target/release/heat_ghosts \
	swift/heat/heat_ghosts \
	hpx/heat/build/bin/heat_ghosts \
	charm/heat/heat_ghosts \
    java/heat/classes/edu/lsu/cct/heat/Main.class

CHARMC=/charm/multicore-linux-x86_64-gcc/bin/charmc
all : $(TARGETS)

clean :
	rm -f $(TARGETS)
	rm -fr hpx/heat/build
	rm -fr java/heat/classes

rust/heat/target/release/heat_ghosts : rust/heat/Cargo.toml rust/heat/src/main.rs rust/heat/src/lib.rs
	(cd rust/heat && cargo build --release)
go/heat/main: go/heat/impl/heat.go go/heat/main.go go/heat/util/util.go
	(cd go/heat && go build -ldflags "-s -w" main.go)
chapel/heat/heat : chapel/heat/heat.chpl
	(cd chapel/heat && chpl --fast heat.chpl)
chapel/heat/heat_ghosts : chapel/heat/heat_ghosts.chpl
	(cd chapel/heat && chpl --fast heat_ghosts.chpl)
cxx/heat/heat_ghosts : cxx/heat/heat_ghosts.cxx
	(cd cxx/heat && g++ -o heat_ghosts -O3 -std=c++17 heat_ghosts.cxx -pthread)
swift/heat/heat_ghosts : swift/heat/heat_ghosts.swift
	(cd swift/heat && swiftc -O heat_ghosts.swift)
hpx/heat/build/bin/heat_ghosts : hpx/heat/heat_ghosts.cxx
	(cd hpx/heat && mkdir -p build && cd build && CMAKE_PREFIX_PATH=/usr/lib64/cmake/ cmake -DCMAKE_BUILD_TYPE=Release .. && $(MAKE))
charm/heat/heat_ghosts : charm/heat/heat_ghosts.cxx
	(cd charm/heat && $(CHARMC) heat_ghosts.ci && $(CHARMC) heat_ghosts.cxx -c++-option -std=c++17 -lstdc++fs -o heat_ghosts -O3 -march=native)
java/heat/classes/edu/lsu/cct/heat/Main.class : java/heat/src/main/java/edu/lsu/cct/heat/Main.java java/heat/src/main/java/edu/lsu/cct/heat/HeatImpl.java
	(cd java/heat && javac -O -d classes/ src/main/java/edu/lsu/cct/heat/Main.java src/main/java/edu/lsu/cct/heat/HeatImpl.java)
