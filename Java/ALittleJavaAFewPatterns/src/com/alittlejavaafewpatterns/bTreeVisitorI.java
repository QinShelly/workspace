package com.alittlejavaafewpatterns;


class IsFlatV implements TreeVisitorI{

    @Override
    public Object forBud() {
        return true;
    }

    @Override
    public Object forFlat(FruitD f, TreeD t) {
        return t.accept(this);
    }

    @Override
    public Object forSplit(TreeD l, TreeD r) {
        return false;
    }
}

class IsSplitV implements TreeVisitorI{

    @Override
    public Object forBud() {
        return true;
    }

    @Override
    public Object forFlat(FruitD f, TreeD t) {
        return false;
    }

    @Override
    public Object forSplit(TreeD l, TreeD r) {
        return (boolean)l.accept(this) && (boolean)r.accept(this);
    }
}

class HasFruitV implements TreeVisitorI{

    @Override
    public Object forBud() {
        return false;
    }

    @Override
    public Object forFlat(FruitD f, TreeD t) {
        return true;
    }

    @Override
    public Object forSplit(TreeD l, TreeD r) {
        return (boolean)l.accept(this) || (boolean)r.accept(this);
    }
}