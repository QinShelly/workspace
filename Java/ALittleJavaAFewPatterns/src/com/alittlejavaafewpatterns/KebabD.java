package com.alittlejavaafewpatterns;

abstract class KebabD {
    public String toString() {
        return "new " + getClass().getName();
    }
    abstract boolean isVeggie();
    abstract Object whatHolder();
}

class Holder extends KebabD {
    Object o;
    Holder(Object _o){
        o = _o;
    }
    public String toString() {
        return "new " + getClass().getName() + "(" + o + ")";
    }

    @Override
    boolean isVeggie() {
        return true;
    }

    @Override
    Object whatHolder() {
        return o;
    }
}

class Shallot extends KebabD {
    KebabD k;
    Shallot(KebabD _k){
        k = _k;
    }
    // ----------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + k + ")";
    }

    @Override
    boolean isVeggie() {
        return k.isVeggie();
    }

    @Override
    Object whatHolder() {
        return k.whatHolder();
    }
}

class Shrimp extends KebabD {
    KebabD k;
    Shrimp(KebabD _k){
        k = _k;
    }
    // ----------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + k + ")";
    }

    @Override
    boolean isVeggie() {
        return false;
    }

    @Override
    Object whatHolder() {
        return k.whatHolder();
    }
}

class Radish extends KebabD {
    KebabD k;
    Radish(KebabD _k){
        k = _k;
    }
    // ----------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + k + ")";
    }

    @Override
    boolean isVeggie() {
        return k.isVeggie();
    }

    @Override
    Object whatHolder() {
        return k.whatHolder();
    }
}

class Pepper extends KebabD {
    KebabD k;
    Pepper(KebabD _k){
        k = _k;
    }
    // ----------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + k + ")";
    }

    @Override
    boolean isVeggie() {
        return k.isVeggie();
    }

    @Override
    Object whatHolder() {
        return k.whatHolder();
    }
}

class Zuchinni extends KebabD {
    KebabD k;
    Zuchinni(KebabD _k){
        k = _k;
    }
    // ----------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + k + ")";
    }

    @Override
    boolean isVeggie() {
        return k.isVeggie();
    }

    @Override
    Object whatHolder() {
        return k.whatHolder();
    }
}