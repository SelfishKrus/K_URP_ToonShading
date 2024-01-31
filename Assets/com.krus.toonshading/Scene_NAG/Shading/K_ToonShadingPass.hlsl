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

        half4 frag_toonShading (v2f i) : SV_Target
    {   
        // ARGS
        Light mainLight = GetMainLight(i.shadowCoord);
        float3 V = normalize(_WorldSpaceCameraPos - i.posWS);
        float3 H = normalize(V + mainLight.direction);
        half NoL = saturate(dot(i.normalWS, mainLight.direction));
        half NoL01 = dot(i.normalWS, mainLight.direction) * 0.5 + 0.5;
        half NoH = saturate(dot(i.normalWS, H));
        half NoV = dot(i.normalWS, V);

        // TEXTURES
        // _IlmTex: r - specular layer; g - shadow offset; b - specular mask; a - outline
        half3 baseCol = SAMPLE_TEXTURE2D(_BaseTex, sampler_BaseTex, i.uv01.xy).rgb;
        half3 sssCol = SAMPLE_TEXTURE2D(_SSSTex, sampler_SSSTex, i.uv01.xy).rgb;
        half4 ilmTex = SAMPLE_TEXTURE2D(_IlmTex, sampler_IlmTex, i.uv01.xy);
        half detailTex = SAMPLE_TEXTURE2D(_DetailTex, sampler_DetailTex, i.uv01.zw).r;
        half shadowOffset = ilmTex.g;
        half AO = i.color.r;
        half specularMask = ilmTex.b;
        half specularLayer = ilmTex.r * 255.0f;

        // Diffuse // 
        half isBright = NoL01 * AO;
        #ifdef _RECEIVE_SHADOWS
            isBright *= mainLight.shadowAttenuation;
        #endif
        isBright = lerp(0.01, 0.99, isBright);
        // isBright = smoothstep(_ShadowThreshold-_ShadowSmoothness, _ShadowThreshold+_ShadowSmoothness, isBright);
        // remap to curve texture
        isBright = SAMPLE_TEXTURE2D(_CurveTexture, sampler_CurveTexture, float2(isBright, 0)).r;
        half3 diffuse = lerp(sssCol*_DarkCol, baseCol*_BrightCol, isBright) * mainLight.color;

        // custom shadow pattern //
        float3 posOS = TransformWorldToObject(i.posWS);

        half3 shadowPattern = SAMPLE_TEXTURE2D(_ShadowPatternTex, sampler_ShadowPatternTex, i.uv3.xy * _Test.x).rgb;
        // half3 shadowPattern = TriplanarSampling(_ShadowPatternTex, sampler_ShadowPatternTex, i.normalWS, i.posWS, _Test.xy, _Test.z).rgb;
        // bool lum_0 = (isBright < 0.1);
        // bool lum_1 = (isBright > 0.2 && isBright < 0.4);
        // bool lum_2 = (isBright >0.5 && isBright < 0.7);
        // bool lum_3 = (isBright > 0.9);
        // diffuse = lum_3 * 1 + (lum_2 * shadowPattern.r, ) + lum_1 * shadowPattern.g + lum_0 * 0;
        // diffuse = lum_2 + lum_1;
        
        float3 customOutput;
        float illum = NoL01 - 0.1;
        
        // customOutput = step(shadowPattern.r, illum);
        customOutput = shadowPattern.r;

        // Specular //
        // feature toggles
        bool rimToggle = (specularLayer >= 45.0f && specularLayer <= 105.0f);
        // hard specular for layer 50 ~ 100
        // bool specularSmoothness = (specularLayer >= 45.0f && specularLayer <= 105.0f) ? _SpecularSmoothness : _SpecularSmoothness;

        // Blinn-phong specular 
        half reflectivity = pow(NoH, _Glossiness) * specularMask;
        reflectivity = smoothstep(_SpecularThreshold - _SpecularSmoothness, _SpecularThreshold + _SpecularSmoothness, reflectivity);
        half3 specular = reflectivity  * mainLight.color * _SpecularCol;
        // specular *= specularToggle;

        // Rim Specular //
        float2 L_VS = TransformWorldToViewDir(mainLight.direction).xy;
        float2 N_VS = TransformWorldToViewDir(i.normalWS).xy;
        float NoL_VS = (dot(N_VS, L_VS)) * 0.5 + 0.5;

        #ifdef _RIM_SPECULAR_SWITCH
            float2 UV_PS = i.pos.xy;
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

        // Outline //
        // sketch 
        half outline = 1;
        #ifdef _TEX_LINES
            outline = detailTex;
        #endif

        #ifdef _UV_LINES
            outline *= ilmTex.a;
        #endif

        // Final Color
        half3 col;
        col = diffuse + specular + rimSpecular;
        col *= outline;

        #ifdef _UV2_CHECK
            col = float3(i.uv2, 1);
        #endif

        #ifdef _MAT_OVERRIDE
            col = 1;
            col *= isBright;
            col *= outline;
            col = customOutput;
        #endif

        return half4(col, 1);
        
    }
    #endif