package com.orion.schedule.test.eureka;

import com.alibaba.fastjson.JSON;
import com.netflix.appinfo.ApplicationInfoManager;
import com.netflix.appinfo.CloudInstanceConfig;
import com.netflix.appinfo.EurekaInstanceConfig;
import com.netflix.appinfo.PropertiesInstanceConfig;
import com.netflix.discovery.CacheRefreshedEvent;
import com.netflix.discovery.DefaultEurekaClientConfig;
import com.netflix.discovery.DiscoveryClient;
import com.netflix.discovery.EurekaClient;
import com.netflix.discovery.shared.Application;
import com.orion.schedule.common.util.InetUtils;

import java.util.Arrays;
import java.util.List;
import java.util.concurrent.TimeUnit;

/**
 * @Description TODO
 * @Author beedoorwei
 * @Date 2020/7/2 16:26
 * @Version 1.0.0
 */
public class Test {
    public static void main(String[] args)throws Exception{

        EurekaClient register = register(20222);

        Application test01 = register.getApplication("TEST01");
        register.registerEventListener(event -> {
            if(!(event instanceof CacheRefreshedEvent)) {
                System.out.println("new event " + JSON.toJSONString(event));
            }
        });

        TimeUnit.SECONDS.sleep(1000L);
    }
    private static EurekaClient register(int port)
    {
        EurekaInstanceConfig eurekaInstanceConfig = new PropertiesInstanceConfig(){
            @Override
            public String getInstanceId() {
                return String.format("%s:%s", InetUtils.getSelfIp(),port);
            }

            @Override
            public String getAppname() {
                return "test01";
            }

            @Override
            public boolean isInstanceEnabledOnit() {
                return true;
            }

            @Override
            public int getLeaseRenewalIntervalInSeconds() {
                return 1;
            }

            @Override
            public int getLeaseExpirationDurationInSeconds() {
                return 3;
            }
        };
        ApplicationInfoManager applicationInfoManager = new ApplicationInfoManager(eurekaInstanceConfig, (ApplicationInfoManager.OptionalArgs) null);
        DefaultEurekaClientConfig defaultEurekaClientConfig = new DefaultEurekaClientConfig() {
            @Override
            public List<String> getEurekaServerServiceUrls(String myZone) {
                return Arrays.asList("http://127.0.0.1:2001/eureka/");
            }

            @Override
            public boolean shouldRegisterWithEureka() {
                return true;
            }

            @Override
            public int getRegistryFetchIntervalSeconds() {
                return 1;
            }
        };
        EurekaClient eurekaClient = new DiscoveryClient(applicationInfoManager, defaultEurekaClientConfig);
        return eurekaClient;
    }
}
