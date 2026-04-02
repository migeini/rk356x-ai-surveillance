#!/bin/sh
export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH

echo "==========================================="
echo "      AI 实时人数监测系统已启动            "
echo "      摄像头: OV5695 (/dev/video0)         "
echo "      按下 Ctrl+C 即可停止监测             "
echo "==========================================="

while true; do
    # 使用 videoflip 在软件层面逆时针翻转 90 度，并使用软件 jpeg 编码绕开不稳定的 RGA 硬件库
    gst-launch-1.0 v4l2src num-buffers=3 device=/dev/video0 ! video/x-raw,format=NV12,width=640,height=480 ! videoflip method=counterclockwise ! videoconvert ! jpegenc ! multifilesink location=/tmp/frame_%02d.jpg > /dev/null 2>&1
    
    # 采用最后一张（曝光最充足的第三帧）
    if [ -f /tmp/frame_02.jpg ]; then
        # 运行 AI 推理（进入 AI 目录保证加载标签文件成功，避免 Segfault）
        cd /root/ai_demo/
        RESULT=$(./rknn_yolov5_demo ./model/yolov5s-640-640.rknn /tmp/frame_02.jpg 2>/dev/null)
        cd - > /dev/null
        
        # 统计 "person" 出现的次数
        PERSON_COUNT=$(echo "$RESULT" | grep -c "person")
        
        # 构造时间戳
        TIMESTAMP=$(date "+%H:%M:%S")
        
        if [ "$PERSON_COUNT" -gt 0 ]; then
            # 告警输出，直接推送到串口
            ALARM_MSG="[AI-$TIMESTAMP] 🚨 警告: 监控区域检测到 $PERSON_COUNT 人！"
            echo "$ALARM_MSG" 
            echo "$ALARM_MSG" > /dev/console 2>/dev/null
        else
            NORMAL_MSG="[AI-$TIMESTAMP] 🟢 安全: 当前区域无人。"
            echo "$NORMAL_MSG"
            echo "$NORMAL_MSG" > /dev/console 2>/dev/null
        fi
    else
        echo "[错误] 抓图失败，正在重试..."
    fi
    
    # 清理照片，短暂休眠后继续下一张
    rm -f /tmp/frame_*.jpg
    sleep 1
done
