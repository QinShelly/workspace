package com.company;

import java.util.Iterator;
import edu.princeton.cs.algs4.StdIn;
import edu.princeton.cs.algs4.StdOut;

public class Queue<Item> implements Iterable<Item> {
    private class Node<Item>{
        Item item;
        Node<Item> next;
    }
    private Node<Item> first;
    private Node last;

    private int N;

    public boolean isEmpty() { return first == null;}
    public int size() { return N; }
    public void enqueue(Item item){
        Node oldlast = last;
        last = new Node();
        last.item = item;
        last.next = null;
        if(isEmpty()) first = last;
        else oldlast.next = last;
        N++;
    }
    public Item dequeue(){
        Item item = first.item;
        first = first.next;
        if(isEmpty()) last = null;
        N--;
        return item;
    }
    public static void main(String[] args) {
        Queue<String> q = new Queue<String>();
        while (!StdIn.isEmpty()){

            String item = StdIn.readString();
            if(!item.equals("-")){
                q.enqueue(item);
            }
            else if (!q.isEmpty()) StdOut.println(q.dequeue() + " ");
        }
        StdOut.println("(" + q.size() + " left on queue)");
    }

    @Override
    public Iterator<Item> iterator() {
        return null;
    }
}
