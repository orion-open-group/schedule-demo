package com.orion.schedule.test.eureka;

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
public class EurekaScheduleStarter {

    private static Logger logger = LoggerFactory.getLogger(EurekaScheduleStarter.class);

    public static void main(String[] args) {
        try {
            SpringApplication springApplication = new SpringApplication(EurekaScheduleStarter.class);
            springApplication.setWebApplicationType(WebApplicationType.NONE);
            springApplication.run();
            TimeUnit.HOURS.sleep(Integer.MAX_VALUE);
        } catch (Throwable e) {
            logger.error("exception happen", e);
        }
    }

}
