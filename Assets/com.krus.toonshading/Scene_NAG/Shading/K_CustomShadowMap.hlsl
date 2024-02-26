#ifndef K_CUSTOM_SHADOW_MAP
#define K_CUSTOM_SHADOW_MAP

    TEXTURE2D(_LightCamDepthTex);     SAMPLER(sampler_LightCamDepthTex);
    float4x4 _LightVP;

    int _CustomShadowPcfStep;
    float _LightCamDepthTex_TexelSize;
    float _LightCam_ShadowBias;

    float2 GetLightCameraScreenUV(float3 posWS)
    {
        float4 posHCS_lightCam = mul(_LightVP, float4(posWS, 1));
        float4 posNDC_lightCam = posHCS_lightCam / posHCS_lightCam.w;
        float2 uv_screen_lightCam = posNDC_lightCam.xy * 0.5 + 0.5;
        return uv_screen_lightCam;
    }

    float SampleCustomShadowMap_PCF(float2 uv_screen_lightCam, float4 posNDC)
    {
        float camDepth = posNDC.z;
        float shadow = 0.0f;
        for (int i = 0; i < _CustomShadowPcfStep ; i++)
        {
            for (int j = 0; j < _CustomShadowPcfStep; j++)
            {
                float2 uv = uv_screen_lightCam + float2(i,j) * _LightCamDepthTex_TexelSize;
                float lightDepth = SAMPLE_TEXTURE2D(_LightCamDepthTex, sampler_LightCamDepthTex, uv).r;
                #if UNITY_REVERSED_Z
                    shadow += camDepth + _LightCam_ShadowBias < lightDepth ? 0.0f : 1.0f;
                #else
                    shadow += camDepth + _LightCam_ShadowBias < lightDepth ? 1.0f : 0.0f;
                #endif
            }
        }

        shadow /= _CustomShadowPcfStep * _CustomShadowPcfStep;

        return shadow;
    }

#endif  