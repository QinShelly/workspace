package com.alittlejavaafewpatterns;

abstract class RodD {
    public String toString() {
        return "new " + getClass().getName();
    }

}

class Dagger extends RodD {

}

class Sabre extends RodD {

}

class Sword extends RodD {

}