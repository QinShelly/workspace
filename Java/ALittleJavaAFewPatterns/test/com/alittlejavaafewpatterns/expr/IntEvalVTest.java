package com.alittlejavaafewpatterns.expr;

import org.junit.Test;

import static org.junit.Assert.*;

public class IntEvalVTest {

    @Test
    public void testIntEvalV() throws Exception {
        assertEquals(5, new Plus(new Const(3), new Const (2))
                .accept(new IntEvalV()));

        assertEquals(1, new Diff(new Const(4), new Const(3))
                .accept(new IntEvalV()));

        assertEquals(12, new Prod(new Const(4), new Const(3))
                .accept(new IntEvalV()));

        // 7 + (4 - 3) * 5
        assertEquals(12, new Plus(new Const(7), new Prod(new Diff(new Const(4), new Const(3)), new Const(5)))
                .accept(new IntEvalV()));
    }
}