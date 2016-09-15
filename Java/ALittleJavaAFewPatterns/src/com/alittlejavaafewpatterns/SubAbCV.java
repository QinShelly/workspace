package com.alittlejavaafewpatterns;

public class SubAbCV {
    public PizzaD forCrust() {
        return new Crust();
    }
    public PizzaD forAnchovy(PizzaD p) {
        return new Cheese(p.subAbC());
    }
    public PizzaD forCheese(PizzaD p) {
        return new Cheese(p.subAbC());
    }
    public PizzaD forOlive(PizzaD p) {
        return new Olive(p.subAbC());
    }
    public PizzaD forSausage(PizzaD p) {
        return new Sausage(p.subAbC());
    }
    public PizzaD forSpinach(PizzaD p) {
        return new Spinach(p.subAbC());
    }
}
