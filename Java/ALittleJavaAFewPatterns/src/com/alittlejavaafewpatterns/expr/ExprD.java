package com.alittlejavaafewpatterns.expr;

abstract class ExprD {
    abstract Object accept(ExprVisitorI ask);
}

class Plus extends ExprD{
    ExprD l;
    ExprD r;
    Plus(ExprD _l, ExprD _r){
        l = _l;
        r = _r;
    }
    // ------------------------------
    @Override
    Object accept(ExprVisitorI ask) {
        return ask.forPlus(l, r);
    }
}

class Diff extends ExprD{
    ExprD l;
    ExprD r;
    Diff(ExprD _l, ExprD _r){
        l = _l;
        r = _r;
    }
    // ------------------------------
    @Override
    Object accept(ExprVisitorI ask) {
        return ask.forDiff(l, r);
    }
}

class Prod extends ExprD{
    ExprD l;
    ExprD r;
    Prod(ExprD _l, ExprD _r){
        l = _l;
        r = _r;
    }
    // ------------------------------
    @Override
    Object accept(ExprVisitorI ask) {
        return ask.forProd(l, r);
    }
}

class Const extends ExprD{
    Object c;
    Const(Object _c){
        c = _c;
    }
    // ------------------------------
    @Override
    Object accept(ExprVisitorI ask) {
        return ask.forConst(c);
    }
}