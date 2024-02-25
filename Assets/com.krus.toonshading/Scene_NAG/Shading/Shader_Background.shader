Shader "Krus/Background"
{
    Properties
    {
        [Toggle(_RECEIVE_CUSTOM_SHADOW)] _RECEIVE_CUSTOM_SHADOW("Receive Custom Shadow", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline" "Queue"="Geometry"}
        LOD 100

        Pass
        {
            Tags {"LightMode"="UniversalForward"}
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _RECEIVE_CUSTOM_SHADOW

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #include "K_CustomShadowMap.hlsl"

            struct appdata
            {
                float4 posOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 posWS : TEXCOORD1;
                float3 normalWS : NORMAL;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            CBUFFER_END

            v2f vert (appdata IN)
            {
                v2f OUT;
                OUT.pos = TransformObjectToHClip(IN.posOS.xyz);
                OUT.posWS = TransformObjectToWorld(IN.posOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag (v2f IN) : SV_Target
            {   
                Light mainLight = GetMainLight();
                float NoL01 = dot(IN.normalWS.xz, -mainLight.direction.xz) * 0.5 + 0.45;
                float2 uv_screen = IN.pos.xy / _ScaledScreenParams.xy;
                float shadow = 1;

                // Custom shadow map
                float2 uv_screen_lightCam = GetLightCameraScreenUV(IN.posWS);
                #ifdef _RECEIVE_CUSTOM_SHADOW
                    shadow *= SampleCustomShadowMap_PCF(uv_screen_lightCam, IN.pos, _LightCam_ShadowBias, _CustomShadowPcfStep);
                #endif

                half3 col = 1;
                col *= shadow;
                return half4(col, 1);
            }
            ENDHLSL
        }

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
    }
}
