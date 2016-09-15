package com.alittlejavaafewpatterns;

import org.junit.Test;

import static org.junit.Assert.*;

public class TransTest {

    @Test
    public void testTransAccept() throws Exception {
        assertEquals(false, new Circle(10).accept(new HasPtV(new CartesianPt(10,10))));

        assertEquals(true, new Square(10).accept(new HasPtV(new CartesianPt(10, 10))));

        assertEquals(true, new Trans(new CartesianPt(5,6),new Circle(10))
                .accept(new HasPtV(new CartesianPt(10, 10))));

        assertEquals(true, new Trans(new CartesianPt(5,4), new Trans(new CartesianPt(5, 6), new Circle(10)))
                .accept(new HasPtV(new CartesianPt(10, 10))));
    }

    @Test
    public void testUnionAccept() throws Exception {
        assertEquals(false, new Trans(new CartesianPt(12,2), new Union(new Square(10),
                new Trans(new CartesianPt(4,4), new Circle(5))))
                .accept(new UnionHasPtV(new CartesianPt(12,16))));

        assertEquals(true, new Trans(new CartesianPt(3,7), new Union(new Square(10),
                new Circle(10)))
                .accept(new UnionHasPtV(new CartesianPt(13,17))));

        assertEquals(true, new Trans(new CartesianPt(3,7), new Square(10))
        .accept(new UnionHasPtV(new CartesianPt(13, 17))));

        assertEquals(false,  new Union(new Square(10),
                new Circle(10))
                .accept(new UnionHasPtV(new CartesianPt(13,17))));

    }
}