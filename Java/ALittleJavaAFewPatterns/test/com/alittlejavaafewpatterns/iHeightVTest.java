package com.alittlejavaafewpatterns;

import org.junit.Test;

import static org.junit.Assert.*;

public class iHeightVTest {

    @Test
    public void testForBud() throws Exception {

    }

    @Test
    public void testForFlat() throws Exception {

    }

    @Test
    public void testForSplit() throws Exception {
        assertEquals(1, new Split(
                new Bud(),
                new Bud())
                .accept(new HeightV()));
    }
}