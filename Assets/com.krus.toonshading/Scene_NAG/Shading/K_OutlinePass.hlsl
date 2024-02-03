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

        float3 posOS = IN.posOS.xyz;
        float3 smoothNormalOS = Decode(IN.uv2);
        smoothNormalOS = TransformMayaToUnity(smoothNormalOS);
        posOS += _OutlineOffset * IN.normalOS;

        OUT.pos = TransformObjectToHClip(posOS);
        return OUT;
    }

    half4 frag (v2f IN) : SV_Target
    {
        half3 col;
        col = _OutlineColor;
        return half4(col, 1);
    }

#endif