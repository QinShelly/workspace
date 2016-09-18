package com.company;

import edu.princeton.cs.algs4.In;
import edu.princeton.cs.algs4.StdIn;
import edu.princeton.cs.algs4.StdOut;
import edu.princeton.cs.algs4.Transaction;

public class MinPQ<Key extends Comparable<Key>> {
    private Key[] pq;
    private int N = 0;

    public MinPQ(int maxN){
        pq = (Key[]) new Comparable[maxN + 1];
    }
    public boolean isEmpty(){
        return N == 0;
    }
    public int size(){
        return N;
    }
    public void insert(Key v){
        pq[++N] = v;
        swim(N);
    }
    public Key delMin(){
        Key max = pq[1];
        exch(1, N--);
        pq[N+1] = null;
        sink(1);
        return max;
    }
    private void sink(int k) {
        while (2 * k <= N){
            int j = 2 * k;
            if (j < N && greater(j, j + 1)) {
                j++;
            }
            if (!greater(k, j)) {
                break;
            }
            exch(k, j);
            k = j;
        }
    }
    private void swim(int k){
        while (k > 1 && greater(k/2, k)){
            exch(k/2, k);
            k = k/2;
        }
    }
    private void exch(int i, int j) {
        Key t = pq[i]; pq[i] = pq[j]; pq[j] = t;
    }
    private boolean greater(int i, int j) {
        return pq[i].compareTo(pq[j]) > 0;
    }

    public static void main(String[] args){
        int M = Integer.parseInt(args[0]);
        MinPQ<Transaction> pq = new MinPQ<Transaction>(M+1);

        In in = new In(args[1]);
        while (in.hasNextLine()){
            pq.insert(new Transaction(in.readLine()));
            if(pq.size() > M){
                pq.delMin();
            }
        }
        Stack<Transaction> stack = new Stack<Transaction>();
        while(!pq.isEmpty()) {
            stack.push(pq.delMin());
        }
        for(Transaction t : stack) {
            StdOut.println(t);
        }
    }
}
