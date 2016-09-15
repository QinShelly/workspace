package com.alittlejavaafewpatterns;

abstract class PointD{
    int x;
    int y;
    PointD(int _x, int _y){
        x = _x;
        y = _y;
    }
    // ----------------------------

    boolean closerTo(PointD p){
        return distanceToO() <= p.distanceToO();
    }
    PointD minus(PointD p){
        return new CartesianPt(x - p.x, y - p.y);
    }
    int moveBy(int dx, int dy){
        x = x + dx;
        y = y + dy;

        return distanceToO();
    }
    abstract int distanceToO();
}

class CartesianPt extends PointD {

    CartesianPt(int _x, int _y){
       super(_x,_y);
    }
    // ----------------------------

    public String toString() {
        return "new " + getClass().getName() + "(" + x + ", " + y + ")";
    }

    @Override
    int distanceToO() {
        return (int)Math.sqrt( x * x + y * y);
    }

}

class ManhattanPt extends PointD {

    ManhattanPt(int _x, int _y){
       super(_x,_y);
    }
    // ----------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + x + ", " + y + ")";
    }

    @Override
    int distanceToO() {
        return x + y;
    }
}

class ShadowedManhattonPt extends ManhattanPt {
    int dx;
    int dy;
    ShadowedManhattonPt(int _x, int _y, int _dx, int _dy){
        super(_x,_y);
        dx = _dx;
        dy = _dy;
    }
    // ----------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + x + ", " + y + ", " + dx + ", " + dy + ")";
    }

    @Override
    int distanceToO() {
        return super.distanceToO() + dx + dy;
    }
}


class ShadowedCartesianPt extends CartesianPt {
    int delta_x;
    int delta_y;
    ShadowedCartesianPt(int _x, int _y, int _delta_x, int _delta_y){
        super(_x,_y);
        delta_x = _delta_x;
        delta_y = _delta_y;
    }
    // ----------------------------
    public String toString() {
        return "new " + getClass().getName() + "(" + x + ", " + y + ", " + delta_x + ", " + delta_y + ")";
    }

    @Override
    int distanceToO() {
        return new CartesianPt(x + delta_x, y + delta_y).distanceToO();
    }
}