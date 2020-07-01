package com.orion.schedule.test.db;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.WebApplicationType;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.util.concurrent.TimeUnit;

/**
 * @Description TODO
 * @Author beedoorwei
 * @Date 2019/6/3 6:19
 * @Version 1.0.0
 */
@SpringBootApplication
public class DbScheduleStarter {

    private static Logger logger = LoggerFactory.getLogger(DbScheduleStarter.class);

    public static void main(String[] args) {
        try {
            SpringApplication springApplication = new SpringApplication(DbScheduleStarter.class);
            springApplication.setWebApplicationType(WebApplicationType.NONE);
            springApplication.run();
            TimeUnit.HOURS.sleep(Integer.MAX_VALUE);
        } catch (Throwable e) {
            logger.error("exception happen", e);
        }
    }

}
