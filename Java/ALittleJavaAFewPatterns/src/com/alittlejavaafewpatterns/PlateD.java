package com.alittlejavaafewpatterns;

abstract class PlateD {
    public String toString() {
        return "new " + getClass().getName();
    }

}

class Gold extends PlateD {
    public boolean equals(Object o){
        return (o instanceof Gold);
    }
}

class Silver extends PlateD {
    public boolean equals(Object o){
        return (o instanceof Silver);
    }
}

class Brass extends PlateD {
    public boolean equals(Object o){
        return (o instanceof Brass);
    }
}

class Copper extends PlateD {
    public boolean equals(Object o){
        return (o instanceof Copper);
    }
}

class Wood extends PlateD {
    public boolean equals(Object o){
        return (o instanceof Wood);
    }
}