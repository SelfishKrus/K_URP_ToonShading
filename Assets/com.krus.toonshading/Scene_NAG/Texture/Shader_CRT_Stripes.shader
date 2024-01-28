Shader "CustomRenderTexture/Stripes"
{
    Properties
    {
        _Density ("Density", float) = 10
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline" "Queue"="Geometry"}
        LOD 100

        Pass
        {
            Tags {"LightMode"="UniversalForward"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct appdata
            {
                float4 posOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
            float _Density;
            CBUFFER_END



            v2f vert (appdata IN)
            {
                v2f OUT;
                OUT.pos = TransformObjectToHClip(IN.posOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag (v2f IN) : SV_Target
            {
                float stripe_u = floor(IN.uv * _Density) % 2;
                // float stripe_u = sin(IN.uv * _Density);

                half3 col = stripe_u;
                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}
