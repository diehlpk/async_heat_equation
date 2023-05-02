package edu.lsu.cct.heat;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.function.Consumer;
import java.util.function.Supplier;
import java.util.stream.IntStream;

public class HeatImpl {
    private final ThreadPart[] parts;

    public final int nx, nt, threads, channelBufferSize = 12;

    public HeatImpl(int nx, int nt, int threads) {
        this.nx = nx;
        this.nt = nt;
        this.threads = threads;
        this.parts = new ThreadPart[threads];

        var leftGhosts = new Channel[threads];
        for (int i = 0; i < leftGhosts.length; i++) {
            leftGhosts[i] = new Channel(channelBufferSize);
        }

        var rightGhosts = new Channel[threads];
        for (int i = 0; i < rightGhosts.length; i++) {
            rightGhosts[i] = new Channel(channelBufferSize);
        }

        var chunkSize = getChunkSize(nx, threads);

        for (int i = 0, threadNum = 0; i < nx; i += chunkSize) {
            var end = i + chunkSize;

            if (end > nx) {
                end = nx;
            }

            var spaceA = IntStream.range(i, end).asDoubleStream().toArray();
            var spaceB = new double[end - i];

            Consumer<Double> leftTx = leftGhosts[threadNum]::put;
            Consumer<Double> rightTx = rightGhosts[threadNum]::put;

            Supplier<Double> leftRx;
            if (threadNum == 0) {
                leftRx = rightGhosts[threads - 1]::take;
            } else {
                leftRx = rightGhosts[threadNum - 1]::take;
            }

            Supplier<Double> rightRx;
            if (threadNum == threads - 1) {
                rightRx = leftGhosts[0]::take;
            } else {
                rightRx = leftGhosts[threadNum + 1]::take;
            }

            parts[threadNum++] = new ThreadPart(spaceA, spaceB, leftTx, rightTx, leftRx, rightRx);
        }
    }

    public void work() {
        var threadPool = Executors.newFixedThreadPool(this.threads);
        var latch = new CountDownLatch(this.threads);

        for (int threadNum_ = 0; threadNum_ < threads; threadNum_++) {
            final int threadNum = threadNum_;

            threadPool.submit(() -> {
                var threadPart = parts[threadNum];
                var chunkLen = threadPart.chunkLen;
                var current = threadPart.spaceA;
                var aux = threadPart.spaceB;

                for (int t = 0; t < nt; t++) {
                    threadPart.leftTx.accept(current[0]);
                    threadPart.rightTx.accept(current[chunkLen - 1]);

                    aux[0] = heat(threadPart.leftRx.get(), current[0], current[1]);
                    aux[chunkLen - 1] = heat(current[chunkLen - 2], current[chunkLen - 1], threadPart.rightRx.get());

                    for (int idx = 1; idx < chunkLen - 1; idx++) {
                        aux[idx] = heat(current[idx - 1], current[idx], current[idx + 1]);
                    }

                    var tmp = current;
                    current = aux;
                    aux = tmp;
                }

                latch.countDown();
            });
        }

        try {
            latch.await();
        } catch (InterruptedException ignored) { }

        threadPool.shutdown();
    }

    public ArrayList<Double> collectSpace() {
        var list = new ArrayList<Double>(nx);

        for (var part : parts) {
            if (nt % 2 == 0) {
                Arrays.stream(part.spaceA).forEachOrdered(list::add);
            } else {
                Arrays.stream(part.spaceB).forEachOrdered(list::add);
            }
        }

        return list;
    }

    private static class ThreadPart {
        final double[] spaceA, spaceB;
        final int chunkLen;
        final Consumer<Double> leftTx, rightTx;
        final Supplier<Double> leftRx, rightRx;

        public ThreadPart(double[] spaceA, double[] spaceB, Consumer<Double> leftTx, Consumer<Double> rightTx, Supplier<Double> leftRx, Supplier<Double> rightRx) {
            this.spaceA = spaceA;
            this.spaceB = spaceB;
            this.leftTx = leftTx;
            this.rightTx = rightTx;
            this.leftRx = leftRx;
            this.rightRx = rightRx;
            this.chunkLen = spaceA.length;
        }
    }

    private static final class Channel extends ArrayBlockingQueue<Double> {
        public Channel(int capacity) {
            super(capacity);
        }

        @Override
        public void put(Double e) {
            try {
                super.put(e);
            } catch (InterruptedException ignored) { }
        }

        @Override
        public Double take() {
            try {
                return super.take();
            } catch (InterruptedException ignored) { return null; }
        }
    }

    public static double K = 0.4;
    public static double DT = 1.0;
    public static double DX = 1.0;
    public static double CONSTANT_HEAT_TERM = K * DT / (DX * DX);

    public static double heat(double left, double middle, double right) {
        return middle + CONSTANT_HEAT_TERM * (left - 2.0 * middle + right);
    }

    private static int getChunkSize(int nx, int threads) {
        return (int) Math.ceil( ((double)nx) / ((double)threads) );
    }
}
