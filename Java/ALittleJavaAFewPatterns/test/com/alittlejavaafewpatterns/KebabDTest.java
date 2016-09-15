package com.alittlejavaafewpatterns;

import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.*;

public class KebabDTest {
    @Before
    public void setUp() throws Exception {

    }

    @Test
    public void testIsVeggie() throws Exception {
        KebabD s = new Shallot(
                new Radish(
                        new Holder(
                                new Dagger())));
        assertEquals(true, s.isVeggie());

        s = new Shallot(
                new Radish(
                        new Holder(
                                new Gold())));
        assertEquals(true,s.isVeggie());

        s = new Shallot(
                new Shrimp(
                        new Holder(
                                new Gold())));
        assertEquals(false, s.isVeggie());
    }

    @Test
    public void testWhatHolder() throws Exception {
        KebabD s = new Radish(
                new Shallot(
                        new Shrimp(
                                new Holder(new Integer(52)))));
        assertEquals(52, s.whatHolder());

        s = new Radish(
                new Shallot(
                        new Shrimp(
                                new Holder(new Gold()))));
        assertEquals(new Gold(), s.whatHolder());
    }
}