# K_URP_ToonShading
Unity URP Toon Shading Library. 
 
Unity Version: 2023.2.12f1

---
![D%NWMLA2_NW(8Z4A1GCNUXJ](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/e14c8f49-a15e-4f72-a77a-071e3a25e23d)

https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/194d93e4-68e8-40f3-b476-1914dc55ddb7

https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/53d0ee6a-51b1-4c8d-a2e1-28b081e3d525

https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/5ad9029f-ea81-4a52-a30d-30037affc9e7

![Image Sequence_003_0000](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/77fa5d90-099d-4b1c-9760-e7351f4ce644)
![Image Sequence_011_0000](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/6861434b-87dd-4e74-ab29-51424e66988c)
![Image Sequence_007_0000](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/45f3aae5-721a-4523-8895-f9bd3773db02)
![Image Sequence_010_0000](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/a7ab086c-5d55-466c-9d53-f6ae47389ff4)

## Maya

### Toon Shading in ShaderFX

- Toon shader for WYSIWYW
    
    ![dx11 toon shader_](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/64f417a2-bd13-492a-bbbe-795844cc96c7)

    dx11 toon shader 
    

### Encode average normals in uv2 (Deprecated)

- Github address
    
    [https://github.com/SelfishKrus/MayaPython_AverageNormalsToUVs](https://github.com/SelfishKrus/MayaPython_AverageNormalsToUVs)
    
- Encode
    - AverageNormalWS → AverageNormalTS → Encode to uv2 by Octahedron compression
- Decode
    - Decode uv2 → AverageNormalTS → AverageNormalWS

**Deprecated due to undesirable gap of outlines**

## Asset Specification

- _IlmTex
    - r - specular layer
        
        | Specular Layer Value | Material | Feature |
        | --- | --- | --- |
        | 0 | general | no specular, no rim |
        | 50 | general | only rim |
        | 100 | leather | specular and rim |
        | ≥200 | metal | only specular |
      
    - g - shadow offset
    - b - specular range
    - a - inner lines
- Vertex Color
    - r - AO
    - g - position ID
    - b - Z offset for outline offset
    - a - outline thickness
- UV
    - TEXCOORD0 - uv0 - for texture mapping
    - TEXCOORD1 - uv1 - to sample texture for uv lines
    - TEXCOORD2 - uv2 - encoded average normals
    - TEXCOORD3 - uv3 - tri-planar projected uv for shadow hatch
- Tangent
    - as the smooth normal direction for outline offset

## Uber Toon Shader

- Diffuse
    - Control diffuse with AnimationCurve
        
        ![Diffuse illuminance controlled by AnimationCurve](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/f74deabc-17a0-495f-9815-6fcb26f21626)

        Diffuse illuminance controlled by AnimationCurve
      
        ![Pass AnimationCurve to shader as GradientTexture](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/929a1b48-4f55-4d9c-aa30-397e47911e64)

        Pass AnimationCurve to shader as GradientTexture
        
    - Lerp between BaseColor Map and SSSColor Map
        
        ![base color and sss color ](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/a3b3ce3b-0b69-4691-b16d-d6765312c4e6)
        
        base color and sss color
      
- Specular from Direct Light
    
    ![direct light specular ](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/403cc734-3874-464d-b8a4-7ab4776120ec)
    
    direct light specular
    
- Rim Specular
    - option 1 - by depth difference
    - 
        ![Depth Difference Specular ](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/35a06442-cd2a-42d9-98a9-a30ab36b44de)
        
        Depth Difference Specular 
        
    - option 2 - by NoV

        ![NoV Specular](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/3b23950e-8423-4928-aad7-9a782da77962)
        
        NoV Specular
        

## Outline

![Outline ](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/987ff6a9-737e-4c0c-ab98-7487b0ba8664)

Outline 

- Outlines include
    - Back-face extrusion in NDC
    - Edge detection by Sobel depth
- Inner lines include
    - Edge detection by Sobel normal
    - Texture
    - UV lines

## Shadow

- Custom shadow pattern
    - Sample shadow pattern texture via Tri-planar projection UV
        
        ![uv3 - Tri-planar projection UV ](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/1cf63859-07d2-4f9f-9e78-c2396d3deae8)

        uv3 - Tri-planar projection UV 
        
    - Shadow hatch by SD
        
        ![Customized shadow hatch texuture ](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/39420b77-7b38-47d6-8a85-b7cd16ccd070)
      
        Customized shadow hatch texuture 
        
- Custom high-resolution shadow map for character
    - 2048x shadow map
        
        ![Custom high-res shadow map ](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/32814f26-ddd6-471a-91b5-39d42adc32bf)

        Custom high-res shadow map 
        
    - PCSS
        
        ![Percentage closer soft shadow with different PCF step ](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/d303fd4a-a599-4086-b0d7-0707848ec24a)

        Percentage closer soft shadow with different PCF step 
        
    - Supports for directional light mode (orthographic projection) and spot light mode (perspective projection)
        
        ![Orthographic shadow and perspective shadow ](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/74804207-0607-49e4-b66f-a453f22a4bce)

        Orthographic shadow and perspective shadow 
        
    

## Post-Process

- Streak bloom
    
    ![Streak Bloom](https://github.com/SelfishKrus/K_URP_ToonShading/assets/79186991/dc941be5-22f0-48d1-a4d5-1e247dbb9dd2)

    Streak Bloom
    

## Tips

- Dfference between `SampleSceneDepth(float2 uv)` and `LoadSceneDepth(uint2 uv)` in URP Shader Library:
    - SampleSceneDepth
        - screen space uv, ranging from 0 to 1
        - bilinear filter. smoother
    - LoadSceneDepth
        - screen space uv, ranging from 0 to screen pixel size
        - no filtering
- Add DepthOnly Pass in shader to make fragment depth written in _CameraDepthTexture
- Params should make sense to artists, and range being clamped between 0 to 1
- In maya, tangent can’t be modified because it’s determined by UV.
- Coordinate system difference
    - Maya - left-hand coordinate. Y up;
    - Unity - right-hand coordinate; Y up;
- When exporting FBX, make sure coordinate axes of Object Space align with the one of World Space in Maya

## Ref

[Learn how to do stylized shading with Shader Graph - SIGGRAPH 2019](https://www.youtube.com/watch?v=4XxfiwNqU4I)

[一些较少人提过的二次元渲染方法](https://zhuanlan.zhihu.com/p/539950545)

[[UFSH2023]虚幻引擎5全端卡通渲染管线 | YivanLee S1项目_哔哩哔哩_bilibili](https://www.bilibili.com/video/BV13K4y1r7Fm/?spm_id_from=333.788&vd_source=4cc6acb7d8adfa8d884c12f17c0e6850&share_source=weixin)

- Guilty Gear
    
    [【翻译】西川善司「实验做出的游戏图形」「GUILTY GEAR Xrd -SIGN-」中实现的「纯卡通动画的实时3D图形」的秘密，前篇（1） - Trace0429 - 博客园](https://www.cnblogs.com/traceplus/p/4205798.html)
    
    [【翻译】西川善司「实验做出的游戏图形」「GUILTY GEAR Xrd -SIGN-」中实现的「纯卡通动画的实时3D图形」的秘密，前篇（2） - Trace0429 - 博客园](https://www.cnblogs.com/TracePlus/p/4205834.html)
    
    [[卡通渲染]一、罪恶装备角色渲染还原](https://zhuanlan.zhihu.com/p/546396053)
    
- Rim Light
    
    [【JTRP】屏幕空间深度边缘光 Screen Space Depth Rimlight](https://zhuanlan.zhihu.com/p/139290492)
    
    [](https://github.com/JasonMa0012/JTRP/tree/master/Runtime/Shaders/Character)
    
- Outline
    
    [【01】从零开始的卡通渲染-描边篇](https://zhuanlan.zhihu.com/p/109101851)
    
    [【Job/Toon Shading Workflow】自动生成硬表面模型Outline Normal](https://zhuanlan.zhihu.com/p/107664564)
    
    [Maya工作流的平滑法线描边小工具](https://zhuanlan.zhihu.com/p/538660626)
    
    [[Maya API] Vertex tangent space](https://discourse.techart.online/t/maya-api-vertex-tangent-space/4079/2)
    
    [Maya Script](https://www.notion.so/Maya-Script-68c2bb661ea04259acc8c45aadbe3282?pvs=21) 
    
- Custom Shadow map
    
    [Shadow Map原理和改进-腾讯游戏学堂](https://gwb.tencent.com/community/detail/115740)
    
    [高精度 高质量 自适应 角色包围盒阴影 Unity ShadowMap](https://zhuanlan.zhihu.com/p/612448813)
    
    [图形引擎实战：自阴影渲染分享_级联阴影的矩阵怎么计算-CSDN博客](https://blog.csdn.net/qq_41166022/article/details/134458388)
