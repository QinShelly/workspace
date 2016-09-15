package com.alittlejavaafewpatterns;

public class Main {

    public static void main(String[] args) {
        ManhattanPt y = new ManhattanPt(3, 5);
        System.out.println(y.distanceToO());

        CartesianPt c = new CartesianPt(3, 4);
        System.out.println(c.distanceToO());


        ShishD s = new Onion(
                new Tomato(

                        new Skewer()));
        boolean t = s.isVegetarian();
        t = t;
    }
}
