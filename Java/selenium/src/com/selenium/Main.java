package com.selenium;

import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.firefox.FirefoxDriver;

public class Main {

    public static void main(String[] args) {
        WebDriver driver =  new FirefoxDriver();
        driver.get("http://movie.douban.com");

        driver.findElement(By.id("inp-query")).clear();
        driver.findElement(By.id("inp-query")).sendKeys("荒野人");
        driver.findElement(By.cssSelector("input[type=\"submit\"]")).click();
        try {
            Thread.sleep(30000);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        driver.quit();
    }

}
