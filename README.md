这个 shader 可以实现类似于《奥博拉丁的回归》的 1-Bit 风格。

# 功能

1. 将彩色降为可自定义的对比色，并在突变区域提供噪点过渡
2. 忽略远处纹理细节，制造干净的三维效果
3. 使用像素化和噪点模拟复古风格，同时保证噪点的贴附于摄像机而非物体上以避免晕眩

# 实现方法

1. 将连续坐标映射到粗网络上，以实现像素化
2. 通过蓝噪声和抖动制造噪点，并将所有颜色映射为黑白两色
3. 通过裁剪过少噪点实现画面的干净

# 可调节参数：

```
_InputExposure    // HDR 输入的曝光程度，防止过曝
_PixelSize        // 像素化程度，值越大"马赛克"越大
_DitherScale      // 抖动图案的重复平铺密度
_Threshold        // 黑白分割的亮度阈值
_TransitionHardness // 控制突变边缘的硬度
_DitherStrength   // 抖动图案的可视强度
_ShadowClean      // 纯黑区域强度，当像素原始亮度过小时刷为纯黑
_HighlightClean   // 纯白区域强度，当像素原始亮度过大时刷为纯白
_ColorDark/Light  // 最终渲染颜色
```

# 更好表现

可结合 Unity Volume 中的线条强调功能实现更具立体感的效果

# 示例

![https://github.com/Maka486/obra-dinn-postprocess/blob/main/preview.gif](https://github.com/Maka486/obra-dinn-postprocess/blob/main/preview.gif)
