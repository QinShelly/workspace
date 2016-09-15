package com.alittlejavaafewpatterns;

import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.*;

public class PointTest {

    @Before
    public void setUp() throws Exception {

    }

    @Test
    public void testCloserTo() throws Exception {
        assertEquals(true, new CartesianPt(3,4).closerTo(new CartesianPt(12,5)));

        assertEquals(true, new ManhattanPt(1,5).closerTo(new ManhattanPt(3, 4)));

        assertEquals(false, new ManhattanPt(1,5).closerTo(new CartesianPt(3, 4)));

        assertEquals(true, new CartesianPt(3,4).closerTo(new ShadowedCartesianPt(1, 5,1,2)));
    }
}