package com.alittlejavaafewpatterns;

interface TreeVisitorI {
    Object forBud();
    Object forFlat(FruitD f, TreeD t);
    Object forSplit(TreeD l, TreeD r);
}

class HeightV implements TreeVisitorI{
    @Override
    public Object forBud() {
        return 0;
    }

    @Override
    public Object forFlat(FruitD f, TreeD t) {
        return 1 + (int)t.accept(this);
    }

    @Override
    public Object forSplit(TreeD l, TreeD r) {
        return 1 + Math.max((int)l.accept(this), (int)r.accept(this));
    }
}

class OccursV implements TreeVisitorI{
    FruitD a;
    OccursV(FruitD _a){
        a = _a;
    }
    @Override
    public Object forBud() {
        return 0;
    }

    @Override
    public Object forFlat(FruitD f, TreeD t) {
        if (f.equals(a)){
            return 1 + (int)t.accept(this);
        } else {
            return t.accept(this);
        }
    }

    @Override
    public Object forSplit(TreeD l, TreeD r) {
        return (int)l.accept(this) + (int)r.accept(this);
    }
}