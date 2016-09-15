package com.alittlejavaafewpatterns.pie;

import org.junit.Test;

import static org.junit.Assert.*;


public class PiemanMTest {
    @Test
    public void testPiemanM() throws Exception {
        assertEquals(0, new PiemanM().occTop(new Anchovy()));

        assertEquals(1, new PiemanM()
                .addTop(new Anchovy())
                );

    }

    @Test
    public void testPiemanM2() throws Exception {
        PiemanM y = new PiemanM();
        y.addTop(new Anchovy());
        assertEquals(1, y.substTop(new Tuna(), new Anchovy()));
        assertEquals(0, y.occTop(new Anchovy()));
    }

    @Test
    public void testPiemanM3() throws Exception {
        PiemanM yy = new PiemanM();
        yy.addTop(new Anchovy());
        yy.addTop(new Anchovy());
        yy.addTop(new Salmon());
        yy.addTop(new Tuna());
        yy.addTop(new Tuna());
        yy.substTop(new Tuna(), new Anchovy());
        assertEquals(4, yy.substTop(new Tuna(), new Anchovy()));
        assertEquals(0, yy.remTop(new Tuna()));
        assertEquals(1, yy.occTop(new Salmon()));
    }
}