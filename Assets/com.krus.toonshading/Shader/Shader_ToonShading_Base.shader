Shader "Krus/ToonShading"
{
    Properties
    {   
        [Header(Outline)]
        _OutlineOffset ("Outline Offset", Range(0, 0.1)) = 0.01
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)

        [Header(Toon Shading)]
        _BaseMap ("Base Color Map", 2D) = "white" {}
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
            float4 _BaseMap_ST;
            float _OutlineOffset;
            half3 _OutlineColor;
            CBUFFER_END

            TEXTURE2D(_BaseMap);    SAMPLER(sampler_BaseMap);

            v2f vert (appdata v)
            {
                v2f o;

                // float3 bitangentOS = cross(v.normalOS, v.tangentOS.xyz) * v.tangentOS.w;
                // float3x3 tbn = float3x3(v.tangentOS.xyz, bitangentOS, v.normalOS);
                v.posOS.xyz += _OutlineOffset * v.normalOS;

                o.pos = TransformObjectToHClip(v.posOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
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

            struct appdata
            {
                float4 posOS : POSITION;
                float2 uv : TEXCOORD0;
                half3 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                half3 color : COLOR;
            };

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            CBUFFER_END

            TEXTURE2D(_BaseMap);    SAMPLER(sampler_BaseMap);

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.posOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                o.color = v.color;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half3 baseCol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv).rgb;

                half3 col;
                col = baseCol;
                col = i.color;
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
