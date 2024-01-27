Shader "Blit/Outline"
{
    Properties
    {   
        [Toggle(_DEPTH_OUTLINE)] _Depth_Outline("Depth Outline", Float) = 1
        _Depth_Threshold("Depth Threshold", Range(0, 1)) = 0.75
        _Depth_Thickness("Depth Thickness", Range(0, 0.01)) = 0.01
        _Depth_Smoothness("Depth Smoothness", Range(0, 1)) = 0.5
        _Depth_OutlineColor("Depth Outline Color", Color) = (0, 0, 0, 0)

        [Space(30)]

        [Toggle(_NORMAL_OUTLINE)] _Normal_Outline("Normal Outline", Float) = 1
        _Normal_Threshold("Normal Threshold", Range(0, 1)) = 0.75
        _Normal_Thickness("Normal Thickness", Range(0, 0.01)) = 0.01
        _Normal_Smoothness("Normal Smoothness", Range(0, 1)) = 0.5
        _Normal_OutlineColor("Normal Outline Color", Color) = (0, 0, 0, 0)
        _Normal_Bias("Normal Bias", Range(0, 1)) = 0.1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
        ZWrite Off 
        Cull Off
        Pass
        {
            Name "DepthOutlinePass"

            HLSLPROGRAM
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"

            // The Blit.hlsl file provides the vertex shader (Vert),
            // input structure (Attributes) and output strucutre (Varyings)
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            #pragma vertex Vert
            #pragma fragment frag
            #pragma multi_compile _ _DEPTH_OUTLINE
            #pragma multi_compile _ _NORMAL_OUTLINE

            TEXTURE2D_X(_CamColTex);        SAMPLER(sampler_CamColTex);

            float _Depth_Threshold;
            float _Depth_Thickness;
            float _Depth_Smoothness;
            float3 _Depth_OutlineColor;

            float _Normal_Threshold;
            float _Normal_Thickness;
            float _Normal_Smoothness;
            float3 _Normal_OutlineColor;
            float _Normal_Bias;

            half4 frag (Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float4 camColTex = SAMPLE_TEXTURE2D_X(_CamColTex, sampler_CamColTex, input.texcoord);
                float3 outCol = camColTex.rgb;

                // sobel operator 
                const half Gx[9] = {
                    -1, 0, 1,
                    -2, 0, 2,
                    -1, 0, 1
                };
                const half Gy[9] = {
                    1, 2, 1,
                    0, 0, 0,
                    -1, -2, -1
                };

                float depth = SampleSceneDepth(input.texcoord.xy).r;
                float depth01 = Linear01Depth(depth, _ZBufferParams);
                float depthDist = LinearEyeDepth(depth, _ZBufferParams);

                #ifdef _DEPTH_OUTLINE

                    // depth comparison
                    float edgeX_depth = 0;
                    float edgeY_depth = 0;

                    for (int i = 0; i < 9; i++) 
                    {
                        half2 offset = half2(i % 3, i / 3) - half2(1, 1);
                        half depthOffset = SampleSceneDepth(input.texcoord.xy + offset * _Depth_Thickness).r;
                        depthOffset = Linear01Depth(depthOffset, _ZBufferParams);
                        edgeX_depth += depthOffset * Gx[i];
                        edgeY_depth += depthOffset * Gy[i];
                    };

                    edgeX_depth /= 9;
                    edgeY_depth /= 9;

                    float edge_depth = (1 - sqrt(edgeX_depth * edgeX_depth + edgeY_depth * edgeY_depth));
                    edge_depth = smoothstep(_Depth_Threshold-_Depth_Smoothness, _Depth_Threshold+_Depth_Smoothness, edge_depth);

                    outCol = lerp(_Depth_OutlineColor, outCol, edge_depth);

                #endif

                #ifdef _NORMAL_OUTLINE
                
                    // normal comparison
                    float edgeX_normal = 0;
                    float edgeY_normal = 0;
                    
                    for (uint j = 0; j < 9; j++) 
                    {
                        half2 offset = half2(j % 3, j / 3) - half2(1, 1);
                        half3 normalOffset = SampleSceneNormals(input.texcoord.xy + offset * _Normal_Thickness).rgb;
                        edgeX_normal += normalOffset * Gx[j];
                        edgeY_normal += normalOffset * Gy[j];
                    };

                    edgeX_normal /= 9;
                    edgeY_normal /= 9;

                    float edge_normal = (1 - sqrt(edgeX_normal * edgeX_normal + edgeY_normal * edgeY_normal));
                    edge_normal = smoothstep(_Normal_Threshold-_Normal_Smoothness, _Normal_Threshold+_Normal_Smoothness, edge_normal+_Normal_Bias);

                    outCol = lerp(_Normal_OutlineColor, outCol, edge_normal);

                #endif
                
                return float4(outCol, camColTex.a);
            }
            ENDHLSL
        }
    }
}