Shader "Krus/ToonShading"
{
    Properties
    {   
        [Header(Outline)]
        _OutlineOffset ("Outline Offset", Range(0, 0.1)) = 0.01
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        [Space(10)]

        [Header(Toon Shading)]
        _BaseTex ("Base Color Map", 2D) = "white" {}
        _IlmTex ("Ilm Map", 2D) = "white" {}
        _SSSTex ("SSS Map", 2D) = "white" {}
        _DetailTex ("Detail Map", 2D) = "white" {}
        [Space(10)]

        [Header(Shadow)]
        _ShadowThreshold ("Shadow Threshold", Range(0, 1)) = 0.5
        _ShadowSmoothness ("Shadow Smoothness", Range(0, 1)) = 0.01
        
        _Test ("Test", Vector) = (0,0,0,0)

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline" }
        LOD 100

        Pass
        {   
            Tags {"Queue"="Geometry"}
            ZWrite Off
            Cull Front

            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 posOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseTex_ST;
            float _OutlineOffset;
            half3 _OutlineColor;
            float4 _Test;
            CBUFFER_END

            TEXTURE2D(_BaseTex);    SAMPLER(sampler_BaseTex);

            v2f vert (appdata v)
            {
                v2f o;

                // float3 bitangentOS = cross(v.normalOS, v.tangentOS.xyz) * v.tangentOS.w;
                // float3x3 tbn = float3x3(v.tangentOS.xyz, bitangentOS, v.normalOS);
                v.posOS.xyz += _OutlineOffset * v.normalOS;

                o.pos = TransformObjectToHClip(v.posOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _BaseTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half3 col;
                col = _OutlineColor;
                return half4(col, 1);
            }

            ENDHLSL
        }

        Pass
        {
            Tags {"LightMode"="UniversalForward" "Queue"="Geometry"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 posOS : POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float3 normalOS : NORMAL;
                half4 color : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                half4 color : COLOR;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseTex_ST;

            float _ShadowThreshold;
            float _ShadowSmoothness;

            float4 _Test;
            CBUFFER_END

            TEXTURE2D(_BaseTex);    SAMPLER(sampler_BaseTex);
            TEXTURE2D(_IlmTex);     SAMPLER(sampler_IlmTex);
            TEXTURE2D(_SSSTex);     SAMPLER(sampler_SSSTex);
            TEXTURE2D(_DetailTex);  SAMPLER(sampler_DetailTex);

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.posOS.xyz);
                o.uv.xy = v.uv0;
                o.uv.zw = v.uv1;
                o.normalWS = TransformObjectToWorldDir(v.normalOS);
                o.color = v.color;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half3 baseCol = SAMPLE_TEXTURE2D(_BaseTex, sampler_BaseTex, i.uv.xy).rgb;
                half3 sssCol = SAMPLE_TEXTURE2D(_SSSTex, sampler_SSSTex, i.uv.xy).rgb;
                half4 ilmTex = SAMPLE_TEXTURE2D(_IlmTex, sampler_IlmTex, i.uv.xy);
                half detailTex = SAMPLE_TEXTURE2D(_DetailTex, sampler_DetailTex, i.uv.zw).r;
                half shadowOffset = ilmTex.g;
                half AO = i.color.r;
                half outline = ilmTex.a * detailTex;

                // diffuse
                Light mainLight = GetMainLight();
                half NoL = dot(i.normalWS, mainLight.direction) * 0.5 + 0.5;
                // half isBright = smoothstep(_ShadowThreshold, _ShadowThreshold+_ShadowSmoothness, NoL + shadowOffset);
                half isBright = smoothstep(_ShadowThreshold-_ShadowSmoothness, _ShadowThreshold+_ShadowSmoothness, NoL * AO);
                half3 diffuse = lerp(sssCol, baseCol, isBright);

                // specular
                

                half3 col;
                // col = diffuse;
                col = i.color.g;
                col = diffuse;
                
                col *= outline;
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
