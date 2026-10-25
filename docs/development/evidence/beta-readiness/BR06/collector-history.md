# 只读收集器修正历史

首轮包检查在匹配字体路径时FileNotFoundError：Flutter ZIP项为Nunito%5Bwght%5D.ttf，源码为Nunito[wght].ttf。不是资源缺失或构建失败。收集器对ZIP相对路径先URL decode再匹配本地文件，随后完整重跑。无产品/构建工具/资源修改，无第二次构建或签名。
