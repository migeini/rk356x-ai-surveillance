# RK356X AI 实时人数自动化监测系统 (AI-Surveillance)

本项目旨在将 Rockchip (瑞芯微) RK3568/RK3566 系列开发板打造为一个去中心化的边缘 AI 监控设备。它能够控制 V4L2 摄像头自动抓拍、运用 NPU 硬件对图像执行 YOLOv5 推理、执行画面的自动校准，并实时将警告信息播报至系统串口底层终端。

## 🌟 核心特性
- **纯后端解藕**：彻底绕过了会导致段错误的 RGA 硬件加速驱动冲突，使用基于软编码与 C++ OpenCV 魔法旋转融合的最高稳定形态。
- **三重曝光过滤法**：完美避开嵌入式摄像头刚启动常常出现的“首帧绿屏”或“曝光严重不足”问题。
- **全自动 AI 识别与拦截**：集成 YOLOv5 C++ 算法，基于 `rk356x` NPU 加速 1Tops 算力实时监测。
- **串口实时广播**：直接操纵 `/dev/console` 输出跨内核的串口 AI 日志流。

## 📁 目录结构
- `src/` : 经过改造去除了 RGA 污染与添加了自动防倒置功能的 C++ 源码。
- `include/` : C++ 推理头文件。
- `CMakeLists.txt` : 已经移除了 RGA 包绑定的 Cmake 编译文件。
- `person_detector.sh` : [精华] 部署于开发板本身的自动化启动与调度监控神经中枢。
- `build-linux_RK3566_RK3568.sh` : 编译脚本。

## 🚀 如何复现与部署

### 1. 宿主机 (PC端) 交叉编译
将此工程放回原版官方 `rknpu2/examples/` 目录下（为了借用其 3rdparty 第三方库与系统架构配置）。
执行编译指令：
```bash
./build-linux_RK3566_RK3568.sh
```

### 2. 推送至开发板
你需要将编译好的二进制文件、Shell 脚本以及 `yolov5s-640-640.rknn` 模型推送至板卡中：
```bash
scp install/rknn_yolov5_demo_Linux/rknn_yolov5_demo root@<开发板IP>:/root/ai_demo/
scp person_detector.sh root@<开发板IP>:/root/
```

### 3. 在板端守护运行
在板子里的终端执行即可脱离主机掌控自动奔跑：
```bash
nohup /root/person_detector.sh > /root/ai_log.txt 2>&1 &
```
接下来，只要有任何人员踏入摄像头视野，串口终端（如 Minicom）中就会瞬间涌现红色的🚨警告代码。
