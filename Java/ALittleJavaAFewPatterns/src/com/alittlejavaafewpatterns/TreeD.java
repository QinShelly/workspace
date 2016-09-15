package com.alittlejavaafewpatterns;

abstract class TreeD {

    abstract Object accept(TreeVisitorI ask);
}

class Bud extends TreeD{

    @Override
    Object accept(TreeVisitorI ask) {
        return ask.forBud();
    }
}

class Flat extends TreeD{
    FruitD f;
    TreeD t;
    Flat(FruitD _f, TreeD _t){
        f = _f;
        t = _t;
    }
    // ---------------------------------
    @Override
    Object accept(TreeVisitorI ask) {
        return ask.forFlat(f, t);
    }
}

class Split extends TreeD{
    TreeD l;
    TreeD r;
    Split(TreeD _l, TreeD _r){
        l = _l;
        r = _r;
    }
    // --------------------------------
    @Override
    Object accept(TreeVisitorI ask) {
        return ask.forSplit(l, r);
    }
}