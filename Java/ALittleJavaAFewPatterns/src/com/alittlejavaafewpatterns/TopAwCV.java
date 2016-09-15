package com.alittlejavaafewpatterns;


public class TopAwCV {
    public PizzaD forCrust() {
        return new Crust();
    }
    public PizzaD forAnchovy(PizzaD p) {
        return new Cheese(new Anchovy(p.topAwC()));
    }
    public PizzaD forCheese(PizzaD p) {
        return new Cheese(p.topAwC());
    }
    public PizzaD forOlive(PizzaD p) {
        return new Olive(p.topAwC());
    }
    public PizzaD forSausage(PizzaD p) {
        return new Sausage(p.topAwC());
    }
    public PizzaD forSpinach(PizzaD p) {
        return new Spinach(p.topAwC());
    }
}
