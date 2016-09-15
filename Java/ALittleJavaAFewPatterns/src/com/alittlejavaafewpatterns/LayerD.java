package com.alittlejavaafewpatterns;

abstract class LayerD {
}

class Base extends LayerD{
    Object o;
    Base (Object _o){
        o = _o;
    }
    // ----------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + o + ")";
    }
}

class Slice extends LayerD{
    LayerD l;
    Slice(LayerD _l){
        l = _l;
    }
    // -----------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + l + ")";
    }
}