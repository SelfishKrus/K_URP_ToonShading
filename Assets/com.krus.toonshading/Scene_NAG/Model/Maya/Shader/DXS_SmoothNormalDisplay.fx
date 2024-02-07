    // Simple phong shader based on nVidia plastic example

    /******* Lighting Macros *******/
    /** To use "Object-Space" lighting definitions, change these two macros: **/
    #define LIGHT_COORDS "World"
    #define _SPIN_MAX 99999
    // #define OBJECT_SPACE_LIGHTS /* Define if LIGHT_COORDS is "Object" */

    // Case insensitive

    /////////////////////////////////////////////////////////////////////////////
    ////                Space transformation matrix keywords                 ////
    /////////////////////////////////////////////////////////////////////////////

    float4x4 _Matrix_W : WORLD;
    float4x4 _Matrix_W_I : WORLDINVERSE;
    float4x4 _Matrix_W_IT : WORLDINVERSETRANSPOSE;

    float4x4 _Matrix_V : VIEW;
    float4x4 _Matrix_V_I : VIEWINVERSE;
    float4x4 _Matrix_V_IT : VIEWINVERSETRANSPOSE;

    float4x4 _Matrix_P : PROJECTION;
    float4x4 _Matrix_P_I : PROJECTIONINVERSE;
    float4x4 _Matrix_P_IT : PROJECTIONINVERSETRANSPOSE;

    float4x4 _Matrix_WV : WORLDVIEW;
    float4x4 _Matrix_WV_I : WORLDVIEWINVERSE;
    float4x4 _Matrix_WV_IT : WORLDVIEWINVERSETRANSPOSE;

    float4x4 _Matrix_WVP : WORLDVIEWPROJECTION;
    float4x4 _Matrix_WVP_I : WORLDVIEWPROJECTIONINVERSE;
    float4x4 _Matrix_WVP_IT : WORLDVIEWPROJECTIONINVERSETRANSPOSE;

    float4x4 _Matrix_W_T : WORLDTRANSPOSE;
    float4x4 _Matrix_V_T : VIEWTRANSPOSE;
    float4x4 _Matrix_P_T : PROJECTIONTRANSPOSE;
    float4x4 _Matrix_S : VIEWPORT;

    float4x4 _Matrix_VP : VIEWPROJECTION;

    /////////////////////////////////////////////////////////////////////////////
    ////                              Properties                             ////
    /////////////////////////////////////////////////////////////////////////////

    // Texture // 
    
    Texture2D _MainTex
    <
        string UIGroup = "";
        string ResourceName = "";
        string ResourceType = "2D";
	    string UIWidget = "FilePicker";
	    string UIName = "Main Texture";
        int mipmaplevels = 0;
    >;

        RasterizerState rasterizerState
    {   
        // CullMode
        // NONE     - no culling
        // Front    - cull front
        // Back     - cull back
        CullMode = NONE;
        FillMode = SOLID;
    };

    // State blocks //

    DepthStencilState depthStencilState
    {
        DepthEnable = TRUE; 
        StencilEnable = FALSE;
    };
    
    SamplerState samplerState
    {
        Filter = MIN_MAG_MIP_LINEAR;
        AddressU = WRAP;
        AddressV = WRAP;
    };

    // MISC //
    int _Display_VertexOrUV = false;
    int _Extrude_VertexOrUV = false;
    float _OutlineWidth = 0.5f;
    float3 _OutlineColor < string UIWidget = "Color"; >;

    /////////////////////////////////////////////////////////////////////////////
    ////                               Struct                                ////
    /////////////////////////////////////////////////////////////////////////////

    // Vertex Shader Input //

    struct appdata_outline
    {
        float3 pos	: POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float3 binormalOS : BINORMAL;
        float2 UV0 : TEXCOORD0;
        float2 UV1 : TEXCOORD1;
        float2 UV2 : TEXCOORD2;
    };

    struct appdata
    {
        float3 pos	: POSITION;
        float3 normalOS	: NORMAL;
        float4 tangentOS : TANGENT;

        float2 UV0 : TEXCOORD0;
        float2 UV1 : TEXCOORD1;
        float2 UV2 : TEXCOORD2;
    };

    // Vertex Shader Output //

    struct vertexOutput_outline
    {
        float4 hpos	: POSITION;
    };

    struct vertexOutput
    {
        float4 hpos	: POSITION;
        float3 normalWS : NORMAL;

        float2 UV0 : TEXCOORD0;
        float2 UV1 : TEXCOORD1;
        float2 UV2 : TEXCOORD2;

        float3 smoothNormalOS : TEXCOORD3;
        float3 smoothNormalWS : TEXCOORD4;
        float3 normalTS : TEXCOORD5;

    };

    /////////////////////////////////////////////////////////////////////////////
    ////                         Custom Functions                            ////
    /////////////////////////////////////////////////////////////////////////////

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

    float3 SphericalToCartesian(float2 spherical)
    {
    float2 sinCosTheta, sinCosPhi;

    // Remap from [0, 1] to [-1, 1]
    spherical = spherical * 2.0f - 1.0f;

    // theta = spherical.x * pi, [-pi, pi]
    sincos(spherical.x * 3.14159f, sinCosTheta.x, sinCosTheta.y);

    // spherical.y = cos_phi 
    // sqrt(1.0 - spherical.y * spherical.y) = sin_phi
    sinCosPhi = float2(sqrt(1.0 - spherical.y * spherical.y), spherical.y);

    // return float3(cos_theta * sin_phi, sin_theta * sin_phi, cos_phi)
    // return float3(x, y, z)
    return float3(sinCosTheta.y * sinCosPhi.x, sinCosTheta.x * sinCosPhi.x, sinCosPhi.y);    
    }

    /////////////////////////////////////////////////////////////////////////////
    ////                           Vertex Shader                             ////
    /////////////////////////////////////////////////////////////////////////////

    vertexOutput_outline vertexShader_outline(appdata_outline IN)
    {
        vertexOutput_outline OUT = (vertexOutput_outline)0;

        float3 smoothNormalOS = Decode((IN.UV2.xy));
        float3 smoothNormalWS = mul(float4(smoothNormalOS, 0.0f), _Matrix_W).xyz;
        float3 normalWS = mul(float4(IN.normalOS, 0.0f), _Matrix_W).xyz;

        float3 posWS = mul(float4(IN.pos, 1.0f), _Matrix_W).xyz;
        float3 extrudeDirWS = lerp(normalWS, smoothNormalWS, _Extrude_VertexOrUV);
        posWS += extrudeDirWS * _OutlineWidth;

        float4 hpos = mul(float4(posWS, 1.0f), _Matrix_VP);

        OUT.hpos = hpos;
        return OUT;
    }

    vertexOutput vertexShader(appdata IN)
    {   
        vertexOutput OUT = (vertexOutput)0; // to zero out all members

        float3 smoothNormalOS = Decode((IN.UV2));

        // tbn
        float3 normalWS = mul(float4(IN.normalOS, 0.0f), _Matrix_W).xyz;
        
        OUT.hpos = mul(float4(IN.pos, 1.0f), _Matrix_WVP);
        OUT.smoothNormalWS = mul(float4(smoothNormalOS, 0.0f), _Matrix_W).xyz;
        OUT.normalWS = normalWS;
        
        OUT.UV0 = FlipY(IN.UV0);
        return OUT;
    }

    /////////////////////////////////////////////////////////////////////////////
    ////                         Fragment Shader                             ////
    /////////////////////////////////////////////////////////////////////////////

    float4 fragmentShader_outline(vertexOutput_outline IN) : COLOR
    {   
        return float4(_OutlineColor, 1.0f);
    }

    float4 fragmentShader(vertexOutput IN) : COLOR
    {
        float3 finalColor;
            finalColor = IN.smoothNormalWS * _Display_VertexOrUV 
                + IN.normalWS * (1.0f - _Display_VertexOrUV);

        return float4(finalColor, 1.0f);
    }

    /////////////////////////////////////////////////////////////////////////////
    ////                             Technique                               ////
    /////////////////////////////////////////////////////////////////////////////

    // p0 //

    RasterizerState rasterizerState_p0
    {   
        CullMode = Back;
        FillMode = SOLID;
    };

    RasterizerState rasterizerState_p1
    {   
        CullMode = Front;
        FillMode = SOLID;
    };

    // p1 //

    DepthStencilState depthStencilState_p0
    {
        DepthEnable = TRUE;
        DepthWriteMask = 1; 
        StencilEnable = FALSE;
    };

    DepthStencilState depthStencilState_p1
    {
        DepthEnable = TRUE;
        DepthWriteMask = 1; 
        StencilEnable = FALSE;
    };

    technique10 Simple10
    {   
        pass p0
        {   
            SetRasterizerState(rasterizerState_p0);
            SetDepthStencilState(depthStencilState_p0, 0);
            SetVertexShader(CompileShader(vs_5_0, vertexShader_outline()));
            SetHullShader(NULL);
            SetDomainShader(NULL);
            SetGeometryShader(NULL);
            SetPixelShader(CompileShader(ps_5_0,fragmentShader_outline()));
        }

        pass p1
        {   
            SetRasterizerState(rasterizerState_p1);
            SetDepthStencilState(depthStencilState_p1, 0);
            SetVertexShader(CompileShader(vs_5_0, vertexShader()));
            SetHullShader(NULL);
            SetDomainShader(NULL);
            SetGeometryShader(NULL);
            SetPixelShader(CompileShader(ps_5_0,fragmentShader()));
        }
    }


