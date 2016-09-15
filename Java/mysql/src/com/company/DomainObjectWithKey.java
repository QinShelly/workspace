package com.company;

public abstract class DomainObjectWithKey {
    private Key key;

    protected DomainObjectWithKey(Key ID){
        this.key = ID;
    }

    protected DomainObjectWithKey(){}

    public Key getKey(){
        return key;
    }

    public void setKey (Key key){
        this.key = key;
    }
}
