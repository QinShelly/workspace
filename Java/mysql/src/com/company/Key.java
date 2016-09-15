package com.company;

public class Key {
    private Object[] fields;

    public boolean equals(Object obj){
        if(!(obj instanceof Key)) return false;
        Key otherKey = (Key) obj;

        if(this.fields.length!=otherKey.fields.length) return false;

        for(int i = 0; i < fields.length;i++)
            if (!this.fields[i].equals(otherKey.fields[i])) return false;
        return true;
    }

    public Key(Object[] fields) throws Exception{
        checkKeyNotNull(fields);
        this.fields = fields;
    }

    public Key (long arg){
        this.fields = new Object[1];
        this.fields[0] = arg;
    }

    public Key (Object field) throws Exception {
        if(field == null  ) throw new Exception("Cannot have a null key");
        this.fields = new Object[1];
        this.fields[0] = field;
    }

    public Key (Object arg1, Object arg2) throws Exception{
        this.fields = new Object[2];
        this.fields[0] = arg1;
        this.fields[1] = arg2;
        checkKeyNotNull(fields);
    }
    private void checkKeyNotNull(Object[] fields) throws Exception{
        if (fields == null) throw new Exception("Cannot have null key");
        for (int i = 0; i<fields.length; i++){
            if(fields[i] == null)
                throw new Exception("Cannot have a null element of key");
        }
    }

    public Object value(int i){
        return fields[i];
    }

    public Object value() throws Exception{
        checkSingleKey();
        return fields[0];
    }

    private void checkSingleKey() throws Exception{
        if(fields.length > 1)
            throw new Exception("Cannot take value of composite key");
    }

    public long longValue() throws Exception{
        checkSingleKey();
        return longValue(0);
    }

    public long longValue(int i) throws Exception{
        if(!(fields[i] instanceof Long))
            throw new Exception("Cannot take longValue on non long key");
        return ((Long) fields[i]).longValue();
    }
}
