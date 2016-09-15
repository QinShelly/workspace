package com.company;

import java.sql.Connection;
import java.sql.DriverManager;

public class ConnectionFactory {
    public static Connection getDatabaseConnection() throws Exception{
        Class.forName("com.mysql.jdbc.Driver");
        String url = "jdbc:mysql://localhost:3306/test?"
                + "useUnicode=true&characterEncoding=UTF8";
        return DriverManager.getConnection(url);
    }
}
