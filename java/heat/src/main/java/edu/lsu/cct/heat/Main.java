package edu.lsu.cct.heat;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;

import static edu.lsu.cct.heat.HeatImpl.DT;
import static edu.lsu.cct.heat.HeatImpl.DX;

public class Main {
    public static void main(String[] args) throws IOException {
        var threads = Integer.parseInt(args[0]);
        var nt = Integer.parseInt(args[1]);
        var nx = Integer.parseInt(args[2]);

        var h = new HeatImpl(nx, nt, threads);
        var start = Instant.now();

        h.work();

        var end = Instant.now();

        logCsv(h, Duration.between(start, end));

        ArrayList<Double> space = h.collectSpace();
        double avg = space.stream().mapToDouble(d -> d).average().orElse(Double.NaN);

        System.out.printf("Mean: %.2f. We would expect %.2f (%d/2 - 0.5) after a long enough evolution.%n", avg, ((double) nx / 2.0) - 0.5, nx);
    }

    public static void logCsv(HeatImpl h, Duration elapsed) throws IOException {
        Path fileName = Paths.get("perfdata.csv");

        if (!Files.exists(fileName)) {
            Files.writeString(fileName, "lang,nx,nt,threads,dt,dx,seconds\n");
        }

        Files.writeString(fileName, String.format("java,%d,%d,%d,%f,%f,%f\n", h.nx, h.nt, h.threads, DT, DX, ((double)elapsed.toMillis()) / 1000), StandardOpenOption.APPEND);
    }
}
