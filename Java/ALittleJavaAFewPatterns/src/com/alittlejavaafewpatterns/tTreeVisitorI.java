package com.alittlejavaafewpatterns;

class SubstV implements TreeVisitorI{
    FruitD n;
    FruitD o;
    SubstV(FruitD _n, FruitD _o){
        n = _n;
        o = _o;
    }
    // ---------------------------------
    @Override
    public TreeD forBud() {
        return new Bud();
    }

    @Override
    public TreeD forFlat(FruitD f, TreeD t) {
        if(o.equals(f)){
            return new Flat(n, (TreeD)t.accept(this));
        }
        else {
            return new Flat(f, (TreeD)t.accept(this));
        }
    }

    @Override
    public TreeD forSplit(TreeD l, TreeD r) {
        return new Split((TreeD)l.accept(this), (TreeD)r.accept(this));
    }
}