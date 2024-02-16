#ifndef _K_OUTLINE_PASS
#define _K_OUTLINE_PASS

    struct appdata
    {
        float4 posOS : POSITION;
        float3 normalOS : NORMAL;
        float2 uv0 : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
        float2 uv2 : TEXCOORD2;

    };

    struct v2f
    {
        float4 pos : SV_POSITION;
    };

    CBUFFER_START(UnityPerMaterial)
    float4 _BaseTex_ST;
    float _OutlineOffset;
    half3 _OutlineColor;
    float4 _Test;
    CBUFFER_END

    TEXTURE2D(_BaseTex);    SAMPLER(sampler_BaseTex);

    v2f vert (appdata IN)
    {
        v2f OUT;

        #ifdef _NDC_OUTLINE
            OUT.pos = TransformObjectToHClip(IN.posOS);
            float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, IN.normalOS);
			float2 extendDir = normalize(mul((float3x3)UNITY_MATRIX_P, normal.xy));
            OUT.pos.xy += _OutlineOffset * extendDir * OUT.pos.w * 0.01;
        #else
            float3 posOS = IN.posOS.xyz;
            posOS += _OutlineOffset * IN.normalOS;
            OUT.pos = TransformObjectToHClip(posOS);
        #endif

        return OUT;
    }

    half4 frag (v2f IN) : SV_Target
    {
        half3 col;
        col = _OutlineColor;
        return half4(col, 1);
    }

#endif