package com.alittlejavaafewpatterns;

import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.*;

public class ShishDTest {

    @Before
    public void setUp() throws Exception {

    }

    @Test
    public void testOnlyOnions() throws Exception {
        ShishD s = new Onion(
                new Onion(
                        new Onion(
                                new Skewer())));
        assertEquals(true, s.onlyOnions());

        s = new Tomato(
                new Onion(
                        new Onion(
                                new Skewer())));
        assertEquals(false, s.onlyOnions());

        s = new Onion(
                new Tomato(
                        new Onion(
                                new Skewer())));
        assertEquals(false, s.onlyOnions());
    }

    @Test
    public void testIsVegetarian() throws Exception {
        ShishD s = new Onion(
                new Lamb(
                        new Onion(
                                new Skewer())));
        assertEquals(false,s.isVegetarian());

        s = new Tomato(
                        new Onion(
                                new Skewer()));
        assertEquals(true,s.isVegetarian());

         s = new Onion(
                new Tomato(
                        new Onion(
                                new Skewer())));
        assertEquals(true,s.isVegetarian());
    }
}