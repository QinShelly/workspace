package com.alittlejavaafewpatterns.pie;

interface PiemanI{
    int addTop(Object t);
    int remTop(Object t);
    int substTop(Object n, Object o);
    int occTop(Object o);
}

class PiemanM implements PiemanI {
    PieD p = new Bot();
    public int addTop(Object t){
        p = new Top(t,p)
        ;
        return occTop(t);
    }
    public int remTop(Object t){
        p = (PieD)p.accept(new RemV(t))
        ;
        return occTop(t);
    }
    public int substTop(Object n, Object o){
        p = (PieD)p.accept(new SubstV(n, o))
        ;
        return occTop(n);
    }
    public int occTop(Object o){
        return (int)p.accept(new OccursV(o));
    }
}
