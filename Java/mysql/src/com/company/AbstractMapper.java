package com.company;

import java.sql.*;
import java.util.HashMap;
import java.util.Map;

public abstract class AbstractMapper {
    protected Connection DB;
    protected Map loadedMap = new HashMap();

    protected DomainObjectWithKey abstractFind(Key key) throws ClassNotFoundException,SQLException,Exception {
        DB = ConnectionFactory.getDatabaseConnection();

        DomainObjectWithKey result = (DomainObjectWithKey) loadedMap.get(key);
        if (result != null) return  result;
        PreparedStatement findStatement = DB.prepareStatement(findStatement());
        loadFindStatement(key, findStatement);
        ResultSet rs = findStatement.executeQuery();
        rs.next();
        if(rs.isAfterLast()) return null;
        result = load(rs);
        return result;
    }

    abstract protected String findStatement();

    //hook method for the composite key
    protected void loadFindStatement(Key key, PreparedStatement finder) throws Exception{
        finder.setLong(1, key.longValue());
    }

    private DomainObjectWithKey load(ResultSet rs) throws Exception {
        Key key = createKey(rs);
        if(loadedMap.containsKey(key)) return (DomainObjectWithKey)loadedMap.get(key);
        DomainObjectWithKey result = doLoad(key, rs);
        loadedMap.put(key, result);
        return result;
    }

    //hook method for keys that aren't simple integral
    protected Key createKey(ResultSet rs) throws Exception {
        return new Key(rs.getLong(1));
    }

    protected abstract DomainObjectWithKey doLoad(Key id, ResultSet rs) throws Exception;

    public Key insert(DomainObjectWithKey subject) throws SQLException,Exception{
        return performInsert(subject, findNextDatabaseKeyObject());
    }

    private Key findNextDatabaseKeyObject() {
        return new Key(5);
    }

    protected Key performInsert(DomainObjectWithKey subject, Key key) throws Exception{
        subject.setKey(key);
        PreparedStatement stmt = DB.prepareStatement(insertStatementString());
        insertKey(subject, stmt);
        insertData(subject, stmt);
        stmt.execute();
        loadedMap.put(subject.getKey(), subject);
        return subject.getKey();
    }

    abstract protected String insertStatementString();

    protected void insertKey(DomainObjectWithKey subject, PreparedStatement stmt) throws Exception{
        stmt.setLong(1, subject.getKey().longValue());
    }
    protected abstract void insertData(DomainObjectWithKey subject, PreparedStatement stmt) throws SQLException;

    public void update(DomainObjectWithKey subject) throws Exception{
        PreparedStatement stmt = DB.prepareStatement(updateStatementString());
        loadUpdateStatement(subject, stmt);
        stmt.execute();
    }

    protected abstract String updateStatementString();
    protected abstract void loadUpdateStatement(DomainObjectWithKey subject, PreparedStatement stmt) throws Exception;

    public void delete(DomainObjectWithKey subject) throws Exception {
        PreparedStatement stmt = DB.prepareStatement(deleteStatementString());
        loadDeleteStatement(subject,stmt);
        stmt.execute();
    }

    protected  void loadDeleteStatement(DomainObjectWithKey subject, PreparedStatement stmt) throws Exception {
        stmt.setLong(1,subject.getKey().longValue());
    }
    protected abstract String deleteStatementString();
}
