package com.alittlejavaafewpatterns;

abstract class PizzaD {
    RemAV remFn = new RemAV();
    TopAwCV topFn = new TopAwCV();
    SubAbCV subFn = new SubAbCV();
    abstract PizzaD remA();
    abstract PizzaD topAwC();
    abstract PizzaD subAbC();
    public String toString() {
        return "new " + getClass().getName();
    }
}

class Crust extends PizzaD{
    @Override
    PizzaD remA() {
        return remFn.forCrust();
    }

    @Override
    PizzaD topAwC() {
        return topFn.forCrust();
    }

    @Override
    PizzaD subAbC() {
        return subFn.forCrust();
    }
}

class Cheese extends PizzaD{
    PizzaD p;
    Cheese(PizzaD _p){
        p = _p;
    }
    // -------------------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + p + ")";
    }

    @Override
    PizzaD remA() {
        return remFn.forCheese(p);
    }

    @Override
    PizzaD topAwC() {
        return topFn.forCheese(p);
    }

    @Override
    PizzaD subAbC() {
        return subFn.forCheese(p);
    }
}

class Olive extends PizzaD{
    PizzaD p;
    Olive(PizzaD _p){
        p = _p;
    }
    // -------------------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + p + ")";
    }

    @Override
    PizzaD remA() {
        return remFn.forOlive(p);
    }

    @Override
    PizzaD topAwC() {
        return topFn.forOlive(p);
    }

    @Override
    PizzaD subAbC() {
        return subFn.forOlive(p);
    }
}

class Anchovy extends PizzaD{
    PizzaD p;
    Anchovy(PizzaD _p){
        p = _p;
    }
    // -------------------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + p + ")";
    }
    @Override
    PizzaD remA() {
        return remFn.forAnchovy(p);
    }

    @Override
    PizzaD topAwC() {
        return topFn.forAnchovy(p);
    }

    @Override
    PizzaD subAbC() {
        return subFn.forAnchovy(p);
    }
}

class Sausage extends PizzaD{
    PizzaD p;
    Sausage(PizzaD _p){
        p = _p;
    }
    // -------------------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + p + ")";
    }

    @Override
    PizzaD remA() {
        return remFn.forSausage(p);
    }

    @Override
    PizzaD topAwC() {
        return topFn.forSausage(p);
    }

    @Override
    PizzaD subAbC() {
        return subFn.forSausage(p);
    }
}

class Spinach extends PizzaD{
    PizzaD p;
    Spinach(PizzaD _p){
        p = _p;
    }
    // -------------------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + p + ")";
    }

    @Override
    PizzaD remA() {

        return remFn.forSpinach(p);
    }

    @Override
    PizzaD topAwC() {

        return topFn.forSpinach(p);
    }

    @Override
    PizzaD subAbC() {

        return subFn.forSpinach(p);
    }
}