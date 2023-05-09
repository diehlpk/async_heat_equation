package edu.lsu.cct.heat_mini;

import java.time.Duration;
import java.time.Instant;

import static edu.lsu.cct.heat_mini.HeatImpl.DT;
import static edu.lsu.cct.heat_mini.HeatImpl.DX;

public class Main {
    public static void main(String[] args) {
        var threads = Integer.parseInt(args[0]);
        var nt = Integer.parseInt(args[1]);
        var nx = Integer.parseInt(args[2]);

        var h = new HeatImpl(nx, nt, threads);
        var start = Instant.now();

        h.work();

        var end = Instant.now();

        System.out.printf("java,%d,%d,%d,%f,%f,%f\n%n", h.nx, h.nt, h.threads, DT, DX, ((double)Duration.between(start, end).toMillis()) / 1000);

        if (nx <= 20) {
            System.out.printf("Final grid (NX = %d): %s\n", nx, h.collectSpace());
        }
    }
}
