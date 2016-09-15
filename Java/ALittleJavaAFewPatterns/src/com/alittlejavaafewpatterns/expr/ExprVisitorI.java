package com.alittlejavaafewpatterns.expr;

interface ExprVisitorI {
    Object forPlus(ExprD l, ExprD r);
    Object forDiff(ExprD l, ExprD r);
    Object forProd(ExprD l, ExprD r);
    Object forConst(Object c);
}
abstract class EvalD implements ExprVisitorI{
    @Override
    public Object forPlus(ExprD l, ExprD r) {
        return plus(l.accept(this), r.accept(this));
    }

    @Override
    public Object forDiff(ExprD l, ExprD r) {
        return diff(l.accept(this), r.accept(this));
    }

    @Override
    public Object forProd(ExprD l, ExprD r) {
        return prod(l.accept(this), r.accept(this));
    }

    @Override
    public Object forConst(Object c) {
        return c;
    }

    abstract Object plus(Object l, Object r);

    abstract Object diff(Object l, Object r);

    abstract Object prod(Object l, Object r);
}

class IntEvalV extends EvalD{
    Object plus(Object l, Object r){
        return (int)l + (int)r;
    }

    Object diff(Object l, Object r){
        return (int)l - (int)r;
    }

    Object prod(Object l, Object r){
        return (int)l * (int)r;
    }
}

class SetEvalV extends EvalD {
    @Override
    Object plus(Object l, Object r) {return ((SetD)l).plus((SetD)r);}
    @Override
    Object diff(Object l, Object r) {return ((SetD)l).diff((SetD) r);}
    @Override
    Object prod(Object l, Object r) {return ((SetD)l).prod((SetD) r);}

}