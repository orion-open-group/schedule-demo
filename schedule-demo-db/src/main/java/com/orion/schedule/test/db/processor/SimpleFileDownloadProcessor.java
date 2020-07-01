package com.orion.schedule.test.db.processor;


import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.google.common.collect.Lists;
import com.orion.schedule.context.TaskContextUtils;
import com.orion.schedule.domain.ScheduleTaskMsg;
import com.orion.schedule.processor.distribute.DistributedJobProcessor;

import java.util.List;
import java.util.Random;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * @Description TODO
 * @Author beedoorwei
 * @Date 2019/7/31 9:49
 * @Version 1.0.0
 */
public class SimpleFileDownloadProcessor extends DistributedJobProcessor {
    @Override
    public Long fetchData(ScheduleTaskMsg scheduleTaskMsg) {
        String taskContext = scheduleTaskMsg.getTaskContext();
        JSONObject context = JSON.parseObject(taskContext);
        int cnt = 0;
        for (int i = 0; i < context.getLong("times"); i++) {
            List<Object> processData = Lists.newArrayList();
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("name", "zhangsan");
            jsonObject.put("type", getClass().getName());
            jsonObject.put("age", new Random().nextInt(100));
            processData.add(jsonObject);
            jsonObject = new JSONObject();
            jsonObject.put("name", "zhangsan_" + i);
            jsonObject.put("type", getClass().getName());
            jsonObject.put("age", new Random().nextInt(100));
            processData.add(jsonObject);
            int dispatchCnt = dispatchData(scheduleTaskMsg, processData);
            cnt = cnt + dispatchCnt;
            try {
                TimeUnit.MILLISECONDS.sleep(1);
            } catch (Throwable e) {
            } finally {

            }
        }
        return cnt * 1L;
    }

    @Override
    public int processData(ScheduleTaskMsg scheduleTaskMsg) {
        Random random = new Random();
        try {
            AtomicInteger suc = new AtomicInteger(0);
            JSONObject jsonObject = JSON.parseObject(scheduleTaskMsg.getTaskContext());
            scheduleTaskMsg.getTaskDataList().stream().forEach(param -> {
                if (TaskContextUtils.stateNormal(scheduleTaskMsg)) {
                    try {
                        TimeUnit.MILLISECONDS.sleep(random.nextInt(jsonObject.getInteger("sleep") == null ? 1 : jsonObject.getInteger("sleep")));
                        boolean b = random.nextInt(3) == 1;
                        if (b) {
                            suc.incrementAndGet();
                        }
                    } catch (Exception e) {

                    }
                }
            });
            return suc.get();
        } catch (Throwable e) {
            logger.error("sleep error ", e);
        }
        return 0;
    }
}
