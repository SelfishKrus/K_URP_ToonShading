#ifndef _K_TOON_LIGHTING
#define _K_TOON_LIGHTING

    #include "K_CustomShadowMap.hlsl"

    half _ShadowThreshold;
    half _ShadowSmoothness;

    struct ToonBrdf
    {
        float3 baseColor;
        float3 sssColor;
        float3 ao;
        float3 normal;
        float3 pos;
        float4 posNDC;
    };

    struct RemapCurve
    {
        TEXTURE2D(curveTexture);
        SAMPLER(sampler_curveTexture);
        int vId;
    };

    float GetShadow_DL(Light mainLight, ToonBrdf brdf)
    {
        float shadow = 1.0f;
        #ifdef _RECEIVE_SHADOWS
            shadow = mainLight.shadowAttenuation;
            #ifdef _RECEIVE_CUSTOM_SHADOWS
                float2 uv_screen_lightCam = GetLightCameraScreenUV(brdf.pos);
                shadow *= SampleCustomShadowMap_PCF(uv_screen_lightCam, brdf.posNDC, brdf.normal);
            #endif 
        #endif 

        return shadow;
    }

    // remap diffuse 
    float3 GetIncidentLight_DL(ToonBrdf brdf, Light mainLight, RemapCurve curve)
    {
        float NoL01 = dot(brdf.normal, mainLight.direction) * 0.5 + 0.5;
        float lightIntensity = NoL01;
        lightIntensity *= GetShadow_DL(mainLight, brdf);
        lightIntensity *= brdf.ao;
        lightIntensity = lerp(0.01, 0.99, lightIntensity);
        // remap
        lightIntensity = SAMPLE_TEXTURE2D(curve.curveTexture, curve.sampler_curveTexture, float2(lightIntensity, curve.vId)).r;

        return mainLight.color * lightIntensity;
    }

    float3 GetDiffuse_DL(ToonBrdf brdf, Light mainLight, RemapCurve curve)
    {   
        float3 incidentLight = GetIncidentLight_DL(brdf, mainLight, curve);
        return lerp(brdf.sssColor, brdf.baseColor, incidentLight);
    }
    
    // no remap diffuse 
    float3 GetIncidentLight_DL(ToonBrdf brdf, Light mainLight)
    {
        float NoL01 = dot(brdf.normal, mainLight.direction) * 0.5 + 0.5;
        float lightIntensity = NoL01;
        lightIntensity *= GetShadow_DL(mainLight, brdf);
        lightIntensity *= brdf.ao;
        lightIntensity = lerp(0.01, 0.99, lightIntensity);
        lightIntensity = smoothstep(_ShadowThreshold, _ShadowThreshold+_ShadowSmoothness, lightIntensity);
        
        return mainLight.color * lightIntensity;
    }

    float3 GetDiffuse_DL(ToonBrdf brdf, Light mainLight)
    {   
        float3 incidentLight = GetIncidentLight_DL(brdf, mainLight);
        return lerp(brdf.sssColor, brdf.baseColor, incidentLight);
    }

#endif