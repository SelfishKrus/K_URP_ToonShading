Shader "Krus/ToonShading"
{
    Properties
    {   
        [Toggle(_UV2_CHECK)] _UV2_CHECK ("UV2 Check", float) = 0
        [Toggle(_MAT_OVERRIDE)] _MAT_OVERRIDE ("Material Override", float) = 0
        _NormalSmoothness ("Normal Smoothness", Range(0, 1)) = 0

        [Header(Outline)]
        _OutlineOffset ("Outline Offset", Range(0, 1)) = 0.01
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        [Toggle(_TEX_LINES)]_TexLines ("Tex Lines", float) = 1
        [Toggle(_UV_LINES)]_UVLines ("UV Lines", float) = 1
        [Toggle(_NDC_OUTLINE)]_NdcOutline ("NDC Outline", float) = 1
        [Space(10)]

        [Header(Toon Shading)]
        _BaseTex ("Base Color Map", 2D) = "white" {}
        _IlmTex ("Ilm Map", 2D) = "blue" {}
        _SSSTex ("SSS Map", 2D) = "black" {}
        _DetailTex ("Detail Map", 2D) = "white" {}
        [Space(10)]

        [Header(Diffuse)]
        _BrightCol ("Bright Color", Color) = (1, 1, 1, 1)
        _DarkCol ("Dark Color", Color) = (1, 1, 1, 1)
        _ShadowThreshold ("Shadow Threshold", Range(0, 1)) = 0.5
        _ShadowSmoothness ("Shadow Smoothness", Range(0, 1)) = 0.0
        [Space(10)]

        [Header(Direct Light Specular)]
        [Toggle(_DIRECT_LIGHT_SPECULAR)]_DirectLightSpecular ("Direct Light Specular", float) = 1
        _Glossiness ("Glossiness", Float) = 5
        _SpecularThreshold ("Specular Threshold", float) = 0.35
        _SpecularSmoothness ("Specular Smoothness", float) = 0.0
        _SpecularCol ("Specular Color", Color) = (1, 1, 1, 1)
        [Space(10)]

        [Header(Rim Specular)]
        [Toggle(_RIM_SPECULAR)]_RimSpecular ("Rim Specular", float) = 1
        [Toggle(_RIM_SPECULAR_SWITCH)]_RimSpecularSwitch ("0 - NoV Specular, 1 - DepthDiff Specular", float) = 0
        _RimSpecularWidth ("Rim Specular Width (DepthDiff Only)", Float) = 0.65
        _RimSpecularDetail ("Rim Specular Detail", Float) = 0.35
        _RimSpecularSmoothness ("Rim Specular Smoothness", Float) = 0.05
        _RimSpecularCol ("Rim Specular Color", Color) = (1, 1, 1, 1)
        [Space(10)]
        
        [Header(Shadow)]
        [Toggle(_RECEIVE_SHADOWS)] _ReceiveShadows ("Receive Shadows", Float) = 1
        _ShadowPatternTex ("Shadow Pattern Texture", 2D) = "" {}
        [Space(10)]

        [Header(Emissive)]
        _EmissiveTex ("Emissive Texture", 2D) = "black" {}
        [HDR]_EmissiveCol ("Emissive Color", Color) = (1, 1, 1, 1)
        [Space(10)]
        
        _Test ("Test", Vector) = (0,0,0,0)

    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline" }
        LOD 100

        HLSLINCLUDE
        // Custom Functions //
        float2 FlipY(float2 uv)
        {
            return float2(uv.x, 1.0f - uv.y);
        }

        float3 Decode( float2 f )
        {
            f = f * 2.0 - 1.0;
            
            float3 n = float3( f.x, f.y, 1.0 - abs( f.x ) - abs( f.y ) );
            float t = saturate( -n.z );
            n.xy += n.xy >= 0.0 ? -t : t;
            return normalize( n );
        }

        float3 TransformMayaToUnity(float3 vec)
        {   
            // float3x3 matrix_maya2unity = float3x3(
            //     -1,0,0,
            //     0,0,1,
            //     0,-1,0
            // );
            // return mul(matrix_maya2unity, vec);

            return float3(-vec.x, vec.z, -vec.y);
        }
        ENDHLSL

        Pass
        {   
            Name "ToonShading"
            Tags {"LightMode"="UniversalForward" "Queue"="Geometry"}
            ZWrite On

            HLSLPROGRAM
            #pragma multi_compile _ _RECEIVE_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _DIRECT_LIGHT_SPECULAR
            #pragma multi_compile _ _RIM_SPECULAR
            #pragma multi_compile _ _RIM_SPECULAR_SWITCH
            #pragma multi_compile _ _UV_LINES
            #pragma multi_compile _ _TEX_LINES
            #pragma multi_compile _ _UV2_CHECK
            #pragma multi_compile _ _MAT_OVERRIDE

            #pragma vertex vert_toonShading
            
            #pragma fragment frag_toonShading

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            #include "K_ToonLighting.hlsl"

            #include "K_TriplanarProjection.hlsl"
            #include "K_ToonShadingPass.hlsl"
            #include "K_MonochromeShading.hlsl"
            
            ENDHLSL
        }

        Pass
        {   
            Name "OutlinePass"
            Tags {"Queue"="Geometry+10"}
            ZWrite On
            Cull Front

            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _NDC_OUTLINE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            #include "K_OutlinePass.hlsl"

            ENDHLSL
        }


        /*
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
            #pragma target 3.5 DOTS_INSTANCING_ON

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Universal Pipeline keywords

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
        */

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask R

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
            #pragma target 3.5 DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }
    }
}
