package com.company;

public class Person extends DomainObjectWithKey {
    public String name;

    public Person(Key id, String name) {
        super(id);
        this.name = name;
    }

    public Person(){}

    public void addLineItem(LineItem lineitem) {
        //todo:
    }
}
