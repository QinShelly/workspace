package com.alittlejavaafewpatterns.pie;

abstract class NumD {
}

class Zero extends NumD{
    public boolean equals(Object o){
        return (o instanceof Zero);
    }
}

class OneMoreThan extends NumD{
    NumD predecessor;
    OneMoreThan(NumD _p){
        predecessor = _p;
    }
    // -----------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + predecessor + ")";
    }

    public boolean equals(Object o){
        if (o instanceof OneMoreThan){
            return predecessor.equals(
                    ((OneMoreThan)o).predecessor);
        }
        else {
            return false;
        }
    }
}