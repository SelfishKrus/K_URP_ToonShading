#ifndef _K_TOON_SHADING_PASS
#define _K_TOON_SHADING_PASS

    struct appdata
    {
        float4 posOS : POSITION;
        float2 uv0 : TEXCOORD0;
        float2 uv1 : TEXCOORD1;
        float2 uv2 : TEXCOORD2;
        float2 uv3 : TEXCOORD3;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        half4 color : COLOR;
    };

    struct v2f
    {
        float4 pos : SV_POSITION;
        float4 uv01 : TEXCOORD0;
        float2 uv2 : TEXCOORD1;
        float2 uv3 : TEXCOORD2;
        float3 normalWS : TEXCOORD3;
        float3 posWS : TEXCOORD4;
        float4 shadowCoord : TEXCOORD5;
        half4 color : COLOR;
    };

    CBUFFER_START(UnityPerMaterial)
    float _NormalSmoothness;

    float4 _BaseTex_ST;

    float _ShadowPatternFactor;
    float _ShadowPatternScale;
    half _ShadowThreshold;
    half _ShadowSmoothness;
    half3 _BrightCol;
    half3 _DarkCol;

    half _SpecularThreshold;
    half _SpecularSmoothness;
    half _Glossiness;
    half3 _SpecularCol;

    half _RimSpecularWidth;
    half _RimSpecularDetail;
    half _RimSpecularSmoothness;
    half3 _RimSpecularCol;

    float4 _Test;
    CBUFFER_END

    // remap texture
    // diffuse - 0
    TEXTURE2D(_CurveTexture); SAMPLER(sampler_CurveTexture);
    int _Id_ShadowCurve;

    TEXTURE2D(_BaseTex);            SAMPLER(sampler_BaseTex);
    TEXTURE2D(_IlmTex);             SAMPLER(sampler_IlmTex);
    TEXTURE2D(_SSSTex);             SAMPLER(sampler_SSSTex);
    TEXTURE2D(_DetailTex);          SAMPLER(sampler_DetailTex);

    TEXTURE2D(_ShadowPatternTex);   SAMPLER(sampler_ShadowPatternTex);

    v2f vert_toonShading (appdata v)
    {
        v2f o;
        o.pos = TransformObjectToHClip(v.posOS.xyz);
        o.uv01.xy = v.uv0;
        o.uv01.zw = v.uv1;
        o.uv2 = v.uv2;
        o.uv3 = v.uv3;

        float3 smoothNormalOS = Decode(v.uv2);
        smoothNormalOS = TransformMayaToUnity(smoothNormalOS);
        float3 normalOS = lerp(v.normalOS, smoothNormalOS, _NormalSmoothness);
        // normalOS = normalize(normalOS);

        o.normalWS = TransformObjectToWorldNormal(normalOS);
        o.posWS = TransformObjectToWorld(v.posOS.xyz);
        o.shadowCoord = TransformWorldToShadowCoord(o.posWS);
        // VERTEX COLOR: r - AO; g - position ID; b - ?; a - outline thickness

        o.color = v.color;
        return o;
    }

    half4 frag_toonShading (v2f IN) : SV_Target
    {   
        // ARGS // 
        Light mainLight = GetMainLight(IN.shadowCoord);
        float3 V = normalize(_WorldSpaceCameraPos - IN.posWS);
        float3 H = normalize(V + mainLight.direction);
        half NoL = saturate(dot(IN.normalWS, mainLight.direction));
        half NoL01 = dot(IN.normalWS, mainLight.direction) * 0.5 + 0.5;
        half NoH = saturate(dot(IN.normalWS, H));
        half NoV = dot(IN.normalWS, V);

        // TEXTURES // 
        // _IlmTex: r - specular layer; g - shadow offset; b - specular mask; a - outline
        half3 baseCol = SAMPLE_TEXTURE2D(_BaseTex, sampler_BaseTex, IN.uv01.xy).rgb;
        half3 sssCol = SAMPLE_TEXTURE2D(_SSSTex, sampler_SSSTex, IN.uv01.xy).rgb;
        half4 ilmTex = SAMPLE_TEXTURE2D(_IlmTex, sampler_IlmTex, IN.uv01.xy);
        half detailTex = SAMPLE_TEXTURE2D(_DetailTex, sampler_DetailTex, IN.uv01.zw).r;
        half shadowOffset = ilmTex.g;
        half AO = IN.color.r;
        half specularMask = ilmTex.b;
        half specularLayer = ilmTex.r * 255.0f;

        // PRE // 
        ToonBrdf brdf;
        brdf.baseColor = baseCol;
        brdf.sssColor = sssCol;
        brdf.ao = IN.color.r;
        brdf.normal = IN.normalWS;

        // DIFFUSE // 
        RemapCurve rcDiffuse;
        rcDiffuse.curveTexture = _CurveTexture;
        rcDiffuse.sampler_curveTexture = sampler_CurveTexture;
        rcDiffuse.vId = _Id_ShadowCurve;

        float shadowPattern = SAMPLE_TEXTURE2D(_ShadowPatternTex, sampler_ShadowPatternTex, IN.uv3.xy * _ShadowPatternScale).r;
        shadowPattern = step(shadowPattern * _ShadowPatternFactor, NoL01);

        half3 diffuse = GetDiffuse_DL(brdf, mainLight, rcDiffuse);
        diffuse *= shadowPattern;

        // DIRECT LIGHT SPECULAR //
        #ifdef _DIRECT_LIGHT_SPECULAR
            // feature toggles
            bool rimToggle = (specularLayer >= 45.0f && specularLayer <= 105.0f);
            // hard specular for layer 50 ~ 100
            // bool specularSmoothness = (specularLayer >= 45.0f && specularLayer <= 105.0f) ? _SpecularSmoothness : _SpecularSmoothness;

            // Blinn-phong specular 
            half reflectivity = pow(NoH, _Glossiness) * specularMask;
            reflectivity = smoothstep(_SpecularThreshold - _SpecularSmoothness, _SpecularThreshold + _SpecularSmoothness, reflectivity);
            half3 specular = reflectivity  * mainLight.color * _SpecularCol;
            // specular *= specularToggle;
        #else
            half3 specular = 0;
        #endif

        // RIM SPECULAR //
        #ifdef _RIM_SPECULAR
            float2 L_VS = TransformWorldToViewDir(mainLight.direction).xy;
            float2 N_VS = TransformWorldToViewDir(IN.normalWS).xy;
            float NoL_VS = (dot(N_VS, L_VS)) * 0.5 + 0.5;

            #ifdef _RIM_SPECULAR_SWITCH
                float2 UV_PS = IN.pos.xy;
                _RimSpecularWidth = lerp(0, 10, _RimSpecularWidth);
                float2 offsetUV_PS =  UV_PS + N_VS * _RimSpecularWidth;
                // offsetUV_PS = clamp(offsetUV_PS, 0, _ScreenParams);
                float linearDepth = Linear01Depth(LoadSceneDepth(UV_PS), _ZBufferParams);
                float linearDepth_offset = Linear01Depth(LoadSceneDepth(offsetUV_PS), _ZBufferParams);
                float depthDiff = abs(linearDepth_offset - linearDepth);
                half3 rimSpecular = _RimSpecularCol * smoothstep(_RimSpecularDetail, _RimSpecularDetail+_RimSpecularSmoothness, depthDiff*NoL_VS);
            #else
                half3 rimSpecular = _RimSpecularCol * smoothstep(_RimSpecularDetail, _RimSpecularDetail+_RimSpecularSmoothness,(1-saturate(NoV)) * NoL01 );
            #endif
        #else
            half3 rimSpecular = 0;
        #endif 

        
        // Outline //
        // sketch 
        half outline = 1;
        #ifdef _TEX_LINES
            outline *= detailTex;
        #endif
        #ifdef _UV_LINES
            outline *= ilmTex.a;
        #endif

        // Final Color
        half3 col;
        col = diffuse + specular + rimSpecular;
        col *= outline;

        #ifdef _UV2_CHECK
            col = float3(IN.uv2, 1);
        #endif

        return half4(col, 1);
        
    }

    #endif