package com.company;

public class LineItem extends DomainObjectWithKey {
    public String product;

    public int amount;

    public LineItem(Key id, String product,int amount) {
        super(id);
        this.product = product;
        this.amount = amount;
    }

    public LineItem(){}
}
