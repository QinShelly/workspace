package com.company;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class LineItemMapper extends AbstractMapper {
    private static final String COLUMNS = "peopleID, seq, amount, product";
    protected String findStatement(){
        return "select " + COLUMNS + " from people_lineitem" + " where (peopleid = ?) and (seq = ?)";
    }
    public LineItem find(Key key) throws ClassNotFoundException,SQLException,Exception{
        return (LineItem) abstractFind(key);
    }
    public  LineItem find(long peopleID, long seq) throws ClassNotFoundException,SQLException,Exception{
        Key key = new Key(new Long(peopleID), new Long(seq));
        return (LineItem) abstractFind(key);
    }

    //hook method overridden for the composite key
    protected void loadFindStatement(Key key, PreparedStatement finder) throws Exception{
        finder.setLong(1, personID(key));
        finder.setLong(2, sequenceNumber(key));
    }
    private long sequenceNumber(Key key) throws Exception{
        return key.longValue(1);
    }
    private long personID(Key key) throws Exception {
        return key.longValue(0);
    }

    protected DomainObjectWithKey doLoad(Key key, ResultSet rs) throws Exception {
        PersonMapper personMapper = new PersonMapper();
        Person person = personMapper.find( personID(key));
        return doLoad(key, rs, person);
    }
    protected DomainObjectWithKey doLoad(Key key, ResultSet rs, Person person) throws SQLException {
        int  amount = rs.getInt("amount");
        String product = rs.getString("product");
        LineItem lineitem = new LineItem(key,product, amount);
        person.addLineItem(lineitem); //link to the person
        return lineitem;
    }
    public void loadAllLineItemFor(Person person) throws Exception {
        PreparedStatement stmt = null;
        ResultSet rs = null;
        stmt = DB.prepareStatement(findForOrderString);
        stmt.setLong(1, person.getKey().longValue());
        rs = stmt.executeQuery();
        while (rs.next()){
            load(rs,person);
        }
    }
    private static final String findForOrderString = "selcet peopleID, seq, amount, product " +
            "from people_lineitem " +
            "where peopleid = ?";
    protected DomainObjectWithKey load(ResultSet rs, Person person) throws Exception {
        Key key = createKey(rs);
        if (loadedMap.containsKey(key)) return (DomainObjectWithKey) loadedMap.get(key);
        DomainObjectWithKey result = doLoad(key,rs, person);
        loadedMap.put(key,result);
        return  result;
    }
    //overwrite the default case
    protected Key createKey(ResultSet rs) throws Exception {
        return new Key(new Long(rs.getLong("peopleID")), new Long(rs.getLong("seq")));
    }

    @Override
    protected String insertStatementString() {
        return "insert into people_lineitem values (?, ?, ? , ?)";
    }
    protected void insertKey(DomainObjectWithKey subject, PreparedStatement stmt) throws Exception {
        stmt.setLong(1, personID(subject.getKey()));
        stmt.setLong(2, sequenceNumber(subject.getKey()));
    }
    @Override
    protected void insertData(DomainObjectWithKey subject, PreparedStatement stmt) throws SQLException{
        LineItem lineItem = (LineItem) subject;
        stmt.setInt(3, lineItem.amount);
        stmt.setString(4, lineItem.product);
    }
    public Key insert(DomainObjectWithKey subject) throws SQLException,Exception{
        throw new UnsupportedOperationException("Must supply an person when inserting a line item");
    }
    public Key insert(LineItem lineItem, Person person) throws SQLException,Exception{
        Key key = new Key(person.getKey().value(), getNextSequenceNumber(person));
        return performInsert(lineItem,key);
    }

    @Override
    protected String updateStatementString() {
        return "update people_lineitem set product = ?, amount = ?  where peopleid = ? and seq = ?" ;
    }
    @Override
    protected void loadUpdateStatement(DomainObjectWithKey subject, PreparedStatement stmt) throws Exception{
        LineItem lineitem = (LineItem) subject;
        stmt.setString(1,lineitem.product);
        stmt.setInt(2, lineitem.amount);
        stmt.setInt(3, (int) personID(subject.getKey()));
        stmt.setInt(4, (int) sequenceNumber(subject.getKey()));
        stmt.execute();
    }

    @Override
    protected String deleteStatementString() {
        return "delete from people_lineitem where peopleid = ? and seq = ?";
    }
}
