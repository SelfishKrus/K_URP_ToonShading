Shader "Blit/StrikeBloom"
{   
    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    // The Blit.hlsl file provides the vertex shader (Vert),
    // input structure (Attributes) and output strucutre (Varyings)
    #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

    TEXTURE2D_X(_CamColTex);
    TEXTURE2D(_InputTex);   SAMPLER(sampler_InputTex);

    float4 _InputTex_TexelSize;


    float _Threshold;

    // Prefilter
    // Filter out bright pixels
    half4 FragPrefilter (Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        uint2 uvSS = input.texcoord * _ScreenParams.xy;
        
        float3 col = LOAD_TEXTURE2D_X(_CamColTex, uvSS).rgb;
        // float bright = max(col.r, max(col.g, col.b));
        // col *= max(0, bright - _Threshold) / max(bright, 1e-5);
        col *= max(0, col - _Threshold) / max(col, 1e-5);

        return float4(col, 1);
    }

    // Downsampler
    // Blur horizontally
    // sample points closer to the center have more weight
    float4 FragDownsample (Varyings input) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

        float2 uv = input.texcoord;
        const float dx = _InputTex_TexelSize.x;

        float u0 = uv.x - dx * 5;
        float u1 = uv.x - dx * 3;
        float u2 = uv.x - dx * 1;
        float u3 = uv.x + dx * 1;
        float u4 = uv.x + dx * 3;
        float u5 = uv.x + dx * 5;

        half3 c0 = SAMPLE_TEXTURE2D(_InputTex, sampler_InputTex, float2(u0, uv.y)).rgb;
        half3 c1 = SAMPLE_TEXTURE2D(_InputTex, sampler_InputTex, float2(u1, uv.y)).rgb;
        half3 c2 = SAMPLE_TEXTURE2D(_InputTex, sampler_InputTex, float2(u2, uv.y)).rgb;
        half3 c3 = SAMPLE_TEXTURE2D(_InputTex, sampler_InputTex, float2(u3, uv.y)).rgb;
        half3 c4 = SAMPLE_TEXTURE2D(_InputTex, sampler_InputTex, float2(u4, uv.y)).rgb;
        half3 c5 = SAMPLE_TEXTURE2D(_InputTex, sampler_InputTex, float2(u5, uv.y)).rgb;

        return half4((c0 + c1 * 2 + c2 * 3 + c3 * 3 + c4 * 2 + c5) / 12, 1);
        
    }

    ENDHLSL

    SubShader
    {
        LOD 100
        ZWrite Off 
        Cull Off

        Pass
        {
            Name "Prefilter"

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragPrefilter
            ENDHLSL
        }

        Pass
        {
            Name "Downsample"

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment FragDownsample
            ENDHLSL
        }
    }
}