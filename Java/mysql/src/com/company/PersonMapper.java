package com.company;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class PersonMapper extends AbstractMapper {
    private static final String COLUMNS = "id, name";

    protected String findStatement(){
        return "select " + COLUMNS + " from people" + " where id = ?";
    }

    @Override
    protected DomainObjectWithKey doLoad(Key key, ResultSet rs) throws SQLException {
        String name = rs.getString("name");
        Person person = new Person(key,name);
        return person;
    }

    @Override
    protected void insertData(DomainObjectWithKey subject, PreparedStatement stmt) throws SQLException{
        Person person = (Person) subject;
        stmt.setString(2,person.name);
    }

    @Override
    protected String updateStatementString() {
        return "update people set name = ? where id = ?";
    }

    @Override
    protected void loadUpdateStatement(DomainObjectWithKey subject, PreparedStatement stmt) throws Exception{
        Person person = (Person) subject;
        stmt.setString(1,person.name);
        stmt.setInt(2, (int) subject.getKey().longValue());
        stmt.execute();
    }

    @Override
    protected String deleteStatementString() {
        return "delete from people where id = ?";
    }

    @Override
    protected String insertStatementString() {
        return "insert into people values (?, ?)";
    }

    public Person find(Key key) throws ClassNotFoundException,SQLException,Exception{
        return (Person) abstractFind(key);
    }

    public  Person find(long id) throws ClassNotFoundException,SQLException,Exception{
        return find(new Key(id));
    }


}
