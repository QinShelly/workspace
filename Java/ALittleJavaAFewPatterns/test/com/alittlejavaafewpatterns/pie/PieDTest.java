package com.alittlejavaafewpatterns.pie;


import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.*;

public class PieDTest {
    @Before
    public void setUp() throws Exception {

    }

    @Test
    public void testRem() throws Exception {
        assertEquals(new Bot(), new Top(new Anchovy(),
                new Bot())
                .accept(new RemV(new Anchovy())));

        assertEquals(new Bot(), new Top(new Integer(2), new Bot())
                .accept(new RemV(new Integer(2))));

        assertEquals(new Top(new Integer(3), new Bot()), new Top(new Integer(3), new Bot())
                .accept(new RemV(new Integer(2))));

        assertEquals(new Bot(), new Top(new Anchovy(), new Bot())
                .accept(new RemV(new Anchovy())));

        assertEquals(new Top(new Integer(3), new Bot()), new Top(new Anchovy(), new Top(new Integer(3), new Bot()))
                .accept(new RemV(new Anchovy())));

        assertEquals(new Top(new Anchovy(),
                        new Top(new Integer(3), new Bot())),
                new Top(new Anchovy(),
                new Top(new Integer(3), new Top(new Zero(), new Bot())))
                .accept(new RemV(new Zero())));

    }

    @Test
    public void testSubst() throws Exception {
        assertEquals(new Top(new Salmon(),
                new Top(new Tuna(),
                        new Top(new Salmon(), new Bot()))),
                new Top(new Anchovy(),
                new Top(new Tuna(),
                        new Top(new Anchovy(), new Bot())))
                .accept(new SubstV(new Salmon(), new Anchovy())));

        assertEquals(new Top(new Integer(5),
                        new Top(new Integer(2),
                                new Top(new Integer(5), new Bot()))),
                new Top(new Integer(3),
                new Top(new Integer(2),
                        new Top(new Integer(3), new Bot())))
                .accept(new SubstV(new Integer(5), new Integer(3))));
    }

    @Test
    public void testLtdSubst() throws Exception {
        assertEquals(new Top(new Salmon(),
                        new Top(new Tuna(),
                                new Top(new Salmon(),
                                        new Top(new Tuna(),
                                                new Top(new Anchovy(), new Bot()))))),
                new Top(new Anchovy(),
                        new Top(new Tuna(),
                                new Top(new Anchovy(),
                                        new Top(new Tuna(),
                                                new Top(new Anchovy(), new Bot())))))
                        .accept(new LtdSubstV(2, new Salmon(), new Anchovy())));

        assertEquals(new Top(new Salmon(),
                        new Top(new Tuna(),
                                new Top(new Salmon(),
                                        new Top(new Tuna(),
                                                new Top(new Salmon(), new Bot()))))),
                new Top(new Anchovy(),
                        new Top(new Tuna(),
                                new Top(new Anchovy(),
                                        new Top(new Tuna(),
                                                new Top(new Anchovy(), new Bot())))))
                        .accept(new LtdSubstV(3, new Salmon(), new Anchovy())));
    }
}