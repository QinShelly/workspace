package com.alittlejavaafewpatterns;

import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.*;

public class PizzaTest {

    @Before
    public void setUp() throws Exception {

    }

    @Test
    public void testRemA() throws Exception {
        assertEquals("new com.alittlejavaafewpatterns.Crust", new Anchovy(new Crust()).remA().toString());

        assertEquals("new com.alittlejavaafewpatterns.Olive(new com.alittlejavaafewpatterns.Crust)", new Olive(new Anchovy(
                new Crust())).remA().toString());

        assertEquals("new com.alittlejavaafewpatterns.Cheese(new com.alittlejavaafewpatterns.Cheese(new com.alittlejavaafewpatterns.Crust))", new Cheese(
                new Anchovy(new Cheese(new Crust()))).remA().toString());
    }

    @Test
    public void testTopAwC() throws Exception {

        assertEquals("new com.alittlejavaafewpatterns.Olive(new com.alittlejavaafewpatterns.Cheese(new com.alittlejavaafewpatterns.Sausage(new com.alittlejavaafewpatterns.Crust)))",
                new Olive(new Cheese(
                new Sausage(new Crust())))
                        .topAwC().toString());

        assertEquals("new com.alittlejavaafewpatterns.Olive(new com.alittlejavaafewpatterns.Cheese(new com.alittlejavaafewpatterns.Anchovy(new com.alittlejavaafewpatterns.Cheese(new com.alittlejavaafewpatterns.Cheese(new com.alittlejavaafewpatterns.Anchovy(new com.alittlejavaafewpatterns.Crust))))))",
                new Olive(
                        new Anchovy(new Cheese(new Anchovy(new Crust()))))
                        .topAwC().toString());
    }
}