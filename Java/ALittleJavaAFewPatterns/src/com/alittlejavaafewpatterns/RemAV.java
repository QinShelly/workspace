package com.alittlejavaafewpatterns;

public class RemAV {
    public PizzaD forCrust() {
        return new Crust();
    }
    public PizzaD forAnchovy(PizzaD p) {
        return p.remA();
    }
    public PizzaD forCheese(PizzaD p) {
        return new Cheese(p.remA());
    }
    public PizzaD forOlive(PizzaD p) {
        return new Olive(p.remA());
    }
    public PizzaD forSausage(PizzaD p) {
        return new Sausage(p.remA());
    }
    public PizzaD forSpinach(PizzaD p) {
        return new Spinach(p.remA());
    }
}
