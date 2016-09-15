package com.alittlejavaafewpatterns.pie;

abstract class PieD {
    abstract Object accept(PieVisitorI ask);
    public String toString() {
        return "new " + getClass().getName();
    }
}

class Bot extends PieD {
    @Override
    Object accept(PieVisitorI ask) {
        return ask.forBot(this);
    }

    public boolean equals(Object o){
        return (o instanceof Bot);
    }
}

class Top extends PieD {
    Object t;
    PieD r;
    Top(Object _t, PieD _r){
        t = _t;
        r = _r;
    }
    // ------------------------------

    @Override
    Object accept(PieVisitorI ask) {
        return ask.forTop(this);
    }

    public boolean equals(Object o){
        if (o instanceof Top){
            if (t.equals(((Top) o).t)){
                return r.equals(((Top) o).r);
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    public String toString() {
        return "new " + getClass().getName() + "(" + t + ", " + r + ")";
    }
}