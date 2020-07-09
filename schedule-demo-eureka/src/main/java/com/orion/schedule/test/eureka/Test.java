//package com.orion.schedule.test.eureka;
//
//import ch.qos.logback.classic.LoggerContext;
//import ch.qos.logback.classic.joran.JoranConfigurator;
//import com.netflix.appinfo.ApplicationInfoManager;
//import com.netflix.appinfo.EurekaInstanceConfig;
//import com.netflix.appinfo.InstanceInfo;
//import com.netflix.appinfo.PropertiesInstanceConfig;
//import com.netflix.discovery.DefaultEurekaClientConfig;
//import com.netflix.discovery.DiscoveryClient;
//import com.netflix.discovery.EurekaClient;
//import com.netflix.discovery.StatusChangeEvent;
//import com.netflix.discovery.shared.Application;
//import com.netflix.discovery.shared.Applications;
//import com.orion.schedule.common.util.InetUtils;
//import org.slf4j.Logger;
//import org.slf4j.LoggerFactory;
//
//import java.io.File;
//import java.util.Arrays;
//import java.util.List;
//import java.util.concurrent.Executors;
//import java.util.concurrent.ScheduledExecutorService;
//import java.util.concurrent.TimeUnit;
//
///**
// * @Description TODO
// * @Author beedoorwei
// * @Date 2020/7/2 16:26
// * @Version 1.0.0
// */
//public class Test {
//    static ScheduledExecutorService executorService = Executors.newScheduledThreadPool(5);
//
//    public static void main(String[] args) throws Exception {
//        JoranConfigurator joranConfigurator = new JoranConfigurator();
//        LoggerContext loggerContext = (LoggerContext) org.slf4j.LoggerFactory.getILoggerFactory();
//        joranConfigurator.setContext(loggerContext);
//        loggerContext.reset();
//        File file = new File("D:\\works\\schedule-demo\\schedule-demo-eureka\\src\\main\\resources\\logback-spring.xml");
//        joranConfigurator.doConfigure(file);
//        Logger logger = LoggerFactory.getLogger(Test.class);
//
//        EurekaClient register = register(20223);
//
//
//        Runtime.getRuntime().addShutdownHook(new Thread(() -> {register.shutdown();
//            System.out.println("shutdown success");}));
//
//        executorService.scheduleAtFixedRate(() -> {
//            try {
//                Application test01 = register.getApplication("TEST01");
//                List<InstanceInfo> instances = test01.getInstancesAsIsFromEureka();
//                logger.error("size " + instances.size());
//            } catch (Throwable e) {
//                logger.error("exception ", e);
//
//            }
//        }, 1, 500, TimeUnit.MILLISECONDS);
//
////        register.shutdown();
//
//        TimeUnit.SECONDS.sleep(1000L);
//    }
//
//    private static EurekaClient register(int port) {
//        EurekaInstanceConfig eurekaInstanceConfig = new PropertiesInstanceConfig() {
//            @Override
//            public String getInstanceId() {
//                return String.format("%s:%s", InetUtils.getSelfIp(), port);
//            }
//
//            @Override
//            public String getAppname() {
//                return "TEST01";
//            }
//
//            @Override
//            public boolean isInstanceEnabledOnit() {
//                return true;
//            }
//
//
//            @Override
//            public int getLeaseRenewalIntervalInSeconds() {
//                return 1;
//            }
//
//            @Override
//            public int getLeaseExpirationDurationInSeconds() {
//                return 1;
//            }
//
//
//        };
//        ApplicationInfoManager applicationInfoManager = new ApplicationInfoManager(eurekaInstanceConfig, (ApplicationInfoManager.OptionalArgs) null);
//        DefaultEurekaClientConfig defaultEurekaClientConfig = new DefaultEurekaClientConfig() {
//            @Override
//            public List<String> getEurekaServerServiceUrls(String myZone) {
//                return Arrays.asList("http://127.0.0.1:2001/eureka/");
//            }
//
//            @Override
//            public boolean shouldDisableDelta() {
//                return true;
//            }
//
//            @Override
//            public boolean shouldRegisterWithEureka() {
//                return true;
//            }
//
//            @Override
//            public int getRegistryFetchIntervalSeconds() {
//                return 1;
//            }
//
//        };
//        DiscoveryClient eurekaClient = new DiscoveryClient(applicationInfoManager, defaultEurekaClientConfig);
//        return eurekaClient;
//    }
//}
