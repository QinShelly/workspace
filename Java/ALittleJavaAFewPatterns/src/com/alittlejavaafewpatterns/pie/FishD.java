package com.alittlejavaafewpatterns.pie;

abstract class FishD {
    public String toString() {
        return "new " + getClass().getName();
    }
}

class Anchovy extends FishD{
    public boolean equals(Object o){
        return (o instanceof Anchovy);
    }
}

class Salmon extends FishD{
    public boolean equals(Object o){
        return (o instanceof Salmon);
    }
}

class Tuna extends FishD{
    public boolean equals(Object o){
        return (o instanceof Tuna);
    }
}