package com.company;

import java.sql.*;
import java.util.*;
import java.util.Date;

public class Main {
    public static void main(String[] args) throws Exception{
        PersonMapper personMapper =  new PersonMapper();

        Person person = personMapper.find(3);
        person.name = "kent wood2";
        personMapper.update(person);
        System.out.println(person.name);

        Person person1 = new Person();
        person1.name = "test";
        personMapper.insert(person1);

        personMapper.delete(person1);
    }
}

class Gateway {
    private Connection db;

    public Gateway() throws ClassNotFoundException,SQLException{
        Class.forName("com.mysql.jdbc.Driver");
        String url = "jdbc:mysql://localhost:3306/test?"
                + "useUnicode=true&characterEncoding=UTF8";
        db = DriverManager.getConnection(url);
    }
    public ResultSet findRecordsForPerson() throws SQLException{
        PreparedStatement stmt = db.prepareStatement(sql);
        ResultSet result = stmt.executeQuery();
        return result;
    }

    private static final String sql =
            "select * from person";

    public void insertPerson(int id, String name) throws SQLException{
        PreparedStatement stmt = db.prepareStatement(insertPersonSql);
        stmt.setInt(1, id);
        stmt.setString(2, name);

        stmt.executeUpdate();
    }

    private static final String insertPersonSql = "insert into person(id,name) values(?,?)";
}

class RevenueRecognition {
    private int amount;
    private Date date;
    public RevenueRecognition(int amount, Date date){
        this.amount  = amount;
        this.date = date;
    }
    public int getAmount(){
        return amount;
    }
    boolean isRecognizableBy(Date asOf){
        return asOf.after(date) || asOf.equals(date);
    }
}


class Contract {
    private List revenueRecognition = new ArrayList();

    public int recognizedRevenue(Date asOf) {
        int result = 0;
        Iterator it = revenueRecognition.iterator();
        while (it.hasNext()){
            RevenueRecognition r = (RevenueRecognition) it.next();
            if (r.isRecognizableBy(asOf))
                result = result + r.getAmount();
        }
        return result;
    }

    public int getRevenue() {
        return revenue;
    }

    private Product product;
    private int revenue;
    private Date whenSigned;
    private Long id;

    public Contract(Product product,int revenue, Date whenSigned){
        this.product = product;
        this.revenue = revenue;
        this.whenSigned = whenSigned;
    }

    public Date getWhenSigned() {

        return whenSigned;
    }

    public void addRevenueRecognization(RevenueRecognition revenueRecognition) {

    }

    public void calculateRecognitions(){
        product.calculateRevenueRecognitions(this);
    }
}

class Product{
    private String name;
    private RecognitionStrategy recognitionStrategy;
    public Product(String name, RecognitionStrategy recognitionStrategy){
        this.name = name;
        this.recognitionStrategy = recognitionStrategy;
    }
    public  static Product newWordProcesor(String name){
        return new Product(name, new CompleteRecognitionStrategy());
    }

    public  static Product newSpreadSheet(String name){
        return new Product(name,new ThreeWayRecognizationStrategy(5,10));
    }

    public  static Product newDatabase(String name){
        return new Product(name,new ThreeWayRecognizationStrategy(30,60));
    }

    void calculateRevenueRecognitions(Contract contract){
        recognitionStrategy.calculateRevenueRecognitions(contract);
    }
}

abstract class RecognitionStrategy{
    abstract void calculateRevenueRecognitions(Contract contract);
}

class CompleteRecognitionStrategy extends RecognitionStrategy{
    void calculateRevenueRecognitions(Contract contract){
        contract.addRevenueRecognization(new RevenueRecognition(contract.getRevenue(),
                contract.getWhenSigned()));
    }
}

class ThreeWayRecognizationStrategy extends RecognitionStrategy{
    private int firstRecognizationOffset;
    private int secondRecognizaitonOffset;
    public  ThreeWayRecognizationStrategy(int firstRecognizationOffset,int secondRecognizaitonOffset){
        this.firstRecognizationOffset = firstRecognizationOffset;
        this.secondRecognizaitonOffset = secondRecognizaitonOffset;

    }
    @Override
    void calculateRevenueRecognitions(Contract contract) {
        int div3 = contract.getRevenue() / 3;
        Date d2 = new Date();
        contract.addRevenueRecognization(new RevenueRecognition(div3,  contract.getWhenSigned()));
        contract.addRevenueRecognization(new RevenueRecognition(div3, contract.getWhenSigned()));
        contract.addRevenueRecognization(new RevenueRecognition(div3, contract.getWhenSigned()));
    }
}