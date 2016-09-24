package com.company;


public class SequentialSearchST<Key, Value> {
    private Node first;
    private int n;
    private class Node
    {
        Key key;
        Value val;
        Node next;
        public Node(Key key, Value val, Node next){
            this.key = key;
            this.val = val;
            this.next = next;
        }
    }
    public int size(){return n;}
    public boolean isEmpty() {
        return size() == 0;
    }
    public Value get(Key key){
        for (Node x = first; x != null; x = x.next){
            if (key.equals(x.key)){
                return x.val;
            }
        }
        return null;
    }
    public void put(Key key, Value val){
        if (key == null) throw new NullPointerException("first argument to put() is null");

        if (val == null) {
            delete(key);
            return;
        }
        for(Node x = first; x != null; x = x.next){
            if(key.equals(x.key)){
                x.val = val;
                return;
            }
        }
        first = new Node(key, val, first);
        n++;
    }

    public boolean contains(Key key) {
        if (key == null) throw new NullPointerException("argument to contains() is null");
        return get(key) != null;
    }

    public void delete(Key key) {
        if (key == null) throw new NullPointerException("argument to delete() is null");
        first = delete(first, key);
    }

    // delete key in linked list beginning at Node x
    // warning: function call stack too large if table is large
    private Node delete(Node x, Key key) {
        if (x == null) return null;
        if (key.equals(x.key)) {
            n--;
            return x.next;
        }
        x.next = delete(x.next, key);
        return x;
    }
    public Iterable<Key> keys()  {
        Queue<Key> queue = new Queue<Key>();
        for (Node x = first; x != null; x = x.next)
            queue.enqueue(x.key);
        return queue;
    }
}
