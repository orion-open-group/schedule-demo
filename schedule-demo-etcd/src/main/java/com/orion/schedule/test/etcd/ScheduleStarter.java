package com.orion.schedule.test.etcd;

import com.orion.schedule.config.progress.TaskExecLogService;
import com.orion.schedule.processor.JobProcessor;
import com.orion.schedule.processor.JobProcessorService;
import com.orion.schedule.processor.grid.TestGridJobProcessor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * @Description TODO
 * @Author beedoorwei
 * @Date 2019/6/3 6:19
 * @Version 1.0.0
 */
@SpringBootApplication
public class ScheduleStarter implements CommandLineRunner {

    private Logger logger = LoggerFactory.getLogger(ScheduleStarter.class);

    @Autowired
    private TaskExecLogService taskExecLogService;
    @Autowired
    private JobProcessorService jobProcessorService;

    public static void main(String[] args) {
        SpringApplication.run(ScheduleStarter.class, args);
    }


    @Override
    public void run(String... args) throws Exception {
        logger.info("server start success");
        JobProcessor xx = jobProcessorService.getProcessor(TestGridJobProcessor.class.getName());
        System.out.println(xx);
    }
}
