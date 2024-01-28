Shader "Krus/ToonShading"
{
    Properties
    {   
        [Toggle(_UV2_CHECK)] _UV2_CHECK ("UV2 Check", float) = 0
        [Toggle(_MAT_OVERRIDE)] _MAT_OVERRIDE ("Material Override", float) = 0
        _NormalSmoothness ("Normal Smoothness", Range(0, 1)) = 0

        [Header(Outline)]
        _OutlineOffset ("Outline Offset", Range(0, 0.1)) = 0.01
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        [Toggle(_TEX_LINES)]_TexLines ("Tex Lines", float) = 1
        [Toggle(_UV_LINES)]_UVLines ("UV Lines", float) = 1
        [Space(10)]

        [Header(Toon Shading)]
        _BaseTex ("Base Color Map", 2D) = "white" {}
        _IlmTex ("Ilm Map", 2D) = "white" {}
        _SSSTex ("SSS Map", 2D) = "white" {}
        _DetailTex ("Detail Map", 2D) = "white" {}

        [Header(Diffuse)]
        _BrightCol ("Bright Color", Color) = (1, 1, 1, 1)
        _DarkCol ("Dark Color", Color) = (1, 1, 1, 1)
        _ShadowThreshold ("Shadow Threshold", Range(0, 1)) = 0.5
        _ShadowSmoothness ("Shadow Smoothness", Range(0, 1)) = 0.0

        [Header(Specular)]
        _Glossiness ("Glossiness", Float) = 5
        _SpecularThreshold ("Specular Threshold", float) = 0.35
        _SpecularSmoothness ("Specular Smoothness", float) = 0.0
        _SpecularCol ("Specular Color", Color) = (1, 1, 1, 1)

        [Header(Rim Specular)]
        [Toggle(_RIM_SPECULAR_SWITCH)]_RimSpecularSwitch ("0 - NoV Specular, 1 - DepthDiff Specular", float) = 0
        _RimSpecularWidth ("Rim Specular Width (DepthDiff Only)", Float) = 0.65
        _RimSpecularDetail ("Rim Specular Detail", Float) = 0.35
        _RimSpecularSmoothness ("Rim Specular Smoothness", Float) = 0.05
        _RimSpecularCol ("Rim Specular Color", Color) = (1, 1, 1, 1)
        [Space(10)]

        _Test ("Test", Vector) = (0,0,0,0)
        [Toggle(_RECEIVE_SHADOWS)] _ReceiveShadows ("Receive Shadows", Float) = 1

    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline" }
        LOD 100

        HLSLINCLUDE
        // Custom Functions //
        float2 FlipY(float2 uv)
        {
            return float2(uv.x, 1.0f - uv.y);
        }

        float3 Decode( float2 f )
        {
            f = f * 2.0 - 1.0;
            
            float3 n = float3( f.x, f.y, 1.0 - abs( f.x ) - abs( f.y ) );
            float t = saturate( -n.z );
            n.xy += n.xy >= 0.0 ? -t : t;
            return normalize( n );
        }

        float3 TransformMayaToUnity(float3 vec)
        {   
            // float3x3 matrix_maya2unity = float3x3(
            //     -1,0,0,
            //     0,0,1,
            //     0,-1,0
            // );
            // return mul(matrix_maya2unity, vec);

            return float3(-vec.x, vec.z, -vec.y);
        }
        ENDHLSL

        Pass
        {   
            Name "OutlinePass"
            Tags {"Queue"="Geometry+10"}
            ZWrite On
            Cull Front

            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

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
                posOS += _OutlineOffset * smoothNormalOS;

                OUT.pos = TransformObjectToHClip(posOS);
                return OUT;
            }

            half4 frag (v2f IN) : SV_Target
            {
                half3 col;
                col = _OutlineColor;
                return half4(col, 1);
            }

            ENDHLSL
        }


        Pass
        {   
            Name "ToonShading"
            Tags {"LightMode"="UniversalForward" "Queue"="Geometry"}
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _RECEIVE_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _RIM_SPECULAR_SWITCH
            #pragma multi_compile _ _UV_LINES
            #pragma multi_compile _ _TEX_LINES
            #pragma multi_compile _ _UV2_CHECK
            #pragma multi_compile _ _MAT_OVERRIDE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"

            struct appdata
            {
                float4 posOS : POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float3 normalOS : NORMAL;
                float3 tangentOS : TANGENT;
                half4 color : COLOR;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv01 : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 posWS : TEXCOORD3;
                float4 shadowCoord : TEXCOORD4;
                float3 tangentWS : TEXCOORD5;
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

            TEXTURE2D(_BaseTex);            SAMPLER(sampler_BaseTex);
            TEXTURE2D(_IlmTex);             SAMPLER(sampler_IlmTex);
            TEXTURE2D(_SSSTex);             SAMPLER(sampler_SSSTex);
            TEXTURE2D(_DetailTex);          SAMPLER(sampler_DetailTex);
            // remap texture
            // diffuse - 0
            TEXTURE2D(_CurveTexture); SAMPLER(sampler_CurveTexture);

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.posOS.xyz);
                o.uv01.xy = v.uv0;
                o.uv01.zw = v.uv1;
                o.uv2 = v.uv2;

                float3 smoothNormalOS = Decode(v.uv2);
                smoothNormalOS = TransformMayaToUnity(smoothNormalOS);
                float3 normalOS = lerp(v.normalOS, smoothNormalOS, _NormalSmoothness);
                // normalOS = normalize(normalOS);

                o.normalWS = TransformObjectToWorldNormal(normalOS);
                o.posWS = TransformObjectToWorld(v.posOS.xyz);
                o.shadowCoord = TransformWorldToShadowCoord(o.posWS);
                o.tangentWS = TransformObjectToWorldDir(v.tangentOS);
                // VERTEX COLOR: r - AO; g - position ID; b - ?; a - outline thickness
                o.color = v.color;
                return o;
            }

            half4 frag (v2f i) : SV_Target
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
                isBright = smoothstep(_ShadowThreshold-_ShadowSmoothness, _ShadowThreshold+_ShadowSmoothness, isBright);
                // remap to curve texture
                // isBright = SAMPLE_TEXTURE2D(_CurveTexture, sampler_CurveTexture, float2(isBright, 0)).r;
                half3 diffuse = lerp(sssCol*_DarkCol, baseCol*_BrightCol, isBright) * mainLight.color;

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


                // Examination
                #ifdef _UV2_CHECK
                    col = float3(i.uv2, 1);
                #endif

                #ifdef _MAT_OVERRIDE
                    col = 1;
                    col *= isBright;
                    col *= outline;
                #endif

                return half4(col, 1);
            }
            ENDHLSL
        }

        /*
        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
            #pragma target 3.5 DOTS_INSTANCING_ON

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Universal Pipeline keywords

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
        */

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask R

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "DepthNormals"
            Tags{"LightMode" = "DepthNormals"}

            ZWrite On
            Cull[_Cull]

            HLSLPROGRAM
            #pragma only_renderers gles gles3 glcore d3d11
            #pragma target 2.0

            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON
            #pragma target 3.5 DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }
    }
}
