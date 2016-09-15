package com.alittlejavaafewpatterns;

abstract class ShishD {
    public String toString() {
        return "new " + getClass().getName();
    }

    OnlyOnionsV ooFn = new OnlyOnionsV();
    IsVegetarianV ivFn = new IsVegetarianV();
    abstract boolean onlyOnions();
    abstract boolean isVegetarian();
}

class Skewer extends ShishD {
    public String toString() {
        return "new " + getClass().getName();
    }

    @Override
    boolean onlyOnions() {
        return ooFn.forSkewer();
    }

    @Override
    boolean isVegetarian() {
        return ivFn.forSkewer();
    }
}

class Onion extends ShishD {
    ShishD s;
    Onion(ShishD _s){
        s = _s;
    }
    // ----------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + s + ")";
    }

    @Override
    boolean onlyOnions() {
        return ooFn.forOnion(s);
    }

    @Override
    boolean isVegetarian() {
        return ivFn.forOnion(s);
    }
}

class Lamb extends ShishD {
    ShishD s;
    Lamb(ShishD _s){
        s = _s;
    }
    // ----------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + s + ")";
    }

    @Override
    boolean onlyOnions() {
        return ooFn.forLamb(s);
    }

    @Override
    boolean isVegetarian() {
        return ivFn.forLamb(s);
    }
}

class Tomato extends ShishD {
    ShishD s;
    Tomato(ShishD _s){
        s = _s;
    }
    // ----------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + s + ")";
    }

    @Override
    boolean onlyOnions() {
        return ooFn.forTomato(s);
    }

    @Override
    boolean isVegetarian() {
        return ivFn.forTomato(s);
    }
}