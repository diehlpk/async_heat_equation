all : go/heat/main chapel/heat chapel/heat_ghost cxx/heat rust/heat/target/release/heat

rust/heat/target/release/heat : rust/heat/Cargo.toml rust/heat/src/main.rs rust/heat/src/lib.rs
	(cd rust/heat && cargo build --release)
go/heat/main: go/heat/impl/heat.go go/heat/main.go go/heat/util/util.go
	(cd go/heat && go build -ldflags "-s -w" main.go)
chapel/heat : chapel/heat.chpl
	(cd chapel && chpl --fast heat_ghost.chpl)
chapel/heat_ghost : chapel/heat_ghost.chpl
	(cd chapel && chpl --fast heat_ghost.chpl)
cxx/heat : cxx/heat.cxx
	(cd cxx && g++ -o heat -O3 -std=c++17 heat.cxx -pthread)
