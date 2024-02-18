#ifndef _K_TOON_LIGHTING
#define _K_TOON_LIGHTING

    struct ToonBrdf
    {
        float3 baseColor;
        float3 sssColor;
        float3 ao;
        float3 normal;
    };

    struct RemapCurve
    {
        TEXTURE2D(curveTexture);
        SAMPLER(sampler_curveTexture);
        int vId;
    };

    float3 GetIncidentLight_DL(ToonBrdf brdf, Light mainLight, RemapCurve curve)
    {
        float lightIntensity = dot(brdf.normal, mainLight.direction) * 0.5 + 0.5;
        #ifdef _RECEIVE_SHADOWS
            lightIntensity *= mainLight.shadowAttenuation;
        #endif
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

#endif