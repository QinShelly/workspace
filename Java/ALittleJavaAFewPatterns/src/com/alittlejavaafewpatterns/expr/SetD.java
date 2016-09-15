package com.alittlejavaafewpatterns.expr;

abstract class SetD {
    SetD add(Integer i){
        if (mem(i)){
            return this;
        }
        else {
            return new Add(i, this);
        }
    }
    abstract boolean mem(Integer i);
    abstract SetD plus(SetD s);
    abstract SetD diff(SetD s);
    abstract SetD prod(SetD s);
}

class Empty extends SetD {
    @Override
    boolean mem(Integer i) {
        return false;
    }

    @Override
    SetD plus(SetD s) {
        return s;
    }

    @Override
    SetD diff(SetD s) {
        return new Empty();
    }

    @Override
    SetD prod(SetD s) {
        return new Empty();
    }
}

class Add extends SetD {
    Integer i;
    SetD s;
    Add (Integer _i, SetD _s){
        i = _i;
        s = _s;
    }
    //----------------------------
    @Override
    boolean mem(Integer n) {
        if (i.equals(n)){
            return true;
        } else {
            return s.mem(n);
        }
    }

    @Override
    SetD plus(SetD t) {
        return s.plus(t.add(i));
    }

    @Override
    SetD diff(SetD t) {
        if (t.mem(i)){
            return s.diff(t);
        } else {
            return s.diff(t).add(i);
        }
    }

    @Override
    SetD prod(SetD t) {
        if (t.mem(i)){
            return s.prod(t).add(i);
        } else {
            return s.prod(t);
        }
    }
}