package com.alittlejavaafewpatterns.pie;

interface PieVisitorI{
    Object forBot(Bot that);
    Object forTop(Top that);
}

class RemV implements PieVisitorI {
    Object o;
    RemV (Object _o){
        o = _o;
    }
    // --------------------------------
    public Object forBot(Bot that){
        return new Bot();
    }

    public Object forTop(Top that){
        if(o.equals(that.t)){
            return that.r.accept(this);
        } else {
            return new Top(that.t,(PieD)that.r.accept(this));
        }
    }
}

abstract class SubstD implements PieVisitorI {
    Object n;
    Object o;
    SubstD(Object _n, Object _o){
        n = _n;
        o = _o;
    }
    public Object forBot(Bot that) {
        return new Bot();
    }
    public abstract Object forTop(Top that);
}

class SubstV implements PieVisitorI {
    Object n;
    Object o;
    SubstV(Object _n, Object _o){
        n = _n;
        o = _o;
    }

    // ---------------------------------
    public Object forBot(Bot that){return new Bot();}
    public Object forTop(Top that){
        if(o.equals(that.t)){
            that.t = n;
            that.r.accept(this);
            return that;
            //return new Top(n, (PieD)that.r.accept(this));
        } else {
            that.r.accept(this);
            return that;
            //return new Top(that.t, (PieD)that.r.accept(this));
        }
    }
}

class LtdSubstV extends SubstD {
    int c;

    LtdSubstV(int _c, Object _n, Object _o){
        super(_n, _o);
        c = _c;
    }
    // ---------------------------------

    public Object forTop(Top that){
        if (c == 0){
            return new Top(that.t, that.r);
        } else {
            if(o.equals(that.t)){
                return new Top(n, (PieD)that.r.accept(new LtdSubstV(c - 1, n, o)));
            } else {
                return new Top(that.t, (PieD)that.r.accept(this));
            }
        }
    }
}

class OccursV implements PieVisitorI{
    Object a;
    OccursV(Object _a){
        a = _a;
    }
    //-----------------------------------
    @Override
    public Object forBot(Bot that) {
        return 0;
    }

    @Override
    public Object forTop(Top that) {
        if (that.t.equals(a)){
            return 1 + (int)that.r.accept(this);
        } else {
            return that.r.accept(this);
        }
    }
}