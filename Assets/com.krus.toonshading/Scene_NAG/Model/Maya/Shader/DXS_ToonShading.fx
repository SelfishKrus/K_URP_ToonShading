    // dx11 shader - toon shading

    #define LIGHT_COORDS "World"
    #define _SPIN_MAX 99999

    // Case insensitive

    /////////////////////////////////////////////////////////////////////////////
    ////                        Semantics from CPU                           ////
    /////////////////////////////////////////////////////////////////////////////

    // Space Transform //

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

    float4x4 _Matrix_VP : VIEWPROJECTION;

    float4x4 _Matrix_W_T : WORLDTRANSPOSE;
    float4x4 _Matrix_V_T : VIEWTRANSPOSE;
    float4x4 _Matrix_P_T : PROJECTIONTRANSPOSE;
    float4x4 _Matrix_S : VIEWPORT;

    // Camera //
    float3 _CameraDirectionWS : ViewDirection < string UIType = "None"; >;
    float3 _CameraPositionWS : ViewPosition < string UIType = "None"; >;

    /////////////////////////////////////////////////////////////////////////////
    ////                              Properties                             ////
    /////////////////////////////////////////////////////////////////////////////

    // Light 0 //

    bool _Light0Enable : LIGHTENABLE
	<
		string Object = "Light 0";
		string UIName = "Enable Light 0";
		int UIOrder = 20;
    > = true;

    int _Light0Type : LIGHTTYPE
	<
		string Object = "Light 0";
		string UIName = "Light 0 Type";
		string UIFieldNames ="None:Default:Spot:Point:Directional:Ambient";
		int UIOrder = 21;
		float UIMin = 0;
		float UIMax = 5;
		float UIStep = 1;
	> = 4; // default to Directional

    float3 _Light0Pos : POSITION 
	< 
		string Object = "Light 0";
		string UIName = "Light 0 Position"; 
		string Space = "World"; 
		int UIOrder = 22;
	> = {0, 0, 0}; 

    float3 _Light0Dir : DIRECTION 
	< 
		string Object = "Light 0";
		string UIName = "Light 0 Direction"; 
		string Space = "World"; 
		int UIOrder = 23;
	> = {1.0f, 1.0f, 1.0f}; 

    float3 _Light0Color : LIGHTCOLOR 
	<
		string Object = "Light 0";
        string UIName = "Light 0 Color"; 
        string UIWidget = "Color"; 
        int UIOrder = 24;
	> = { 1.0f, 1.0f, 1.0f};

    float _Light0Intensity : LIGHTINTENSITY 
	<
        string Object = "Light 0";
        string UIName = "Light 0 Intensity"; 
        float UIMin = 0.0;
        float UIMax = _SPIN_MAX;
        float UIStep = 0.01;
        int UIOrder = 24;
	> = { 1.0f };

    // Texture // 

    SamplerState samplerState2D
    {
        Filter = MIN_MAG_MIP_LINEAR;
        AddressU = WRAP;
        AddressV = WRAP;
    };
    
    Texture2D _BaseColorMap
    <
        string UIGroup = "Diffuse";
        string ResourceName = "";
        string ResourceType = "2D";
	    string UIWidget = "FilePicker";
	    string UIName = "";
        int mipmaplevels = 0;
    >;

    Texture2D _SSSColorMap
    <
        string UIGroup = "Diffuse";
        string ResourceName = "";
        string ResourceType = "2D";
	    string UIWidget = "FilePicker";
	    string UIName = "";
        int mipmaplevels = 0;
    >;

    Texture2D _IlmMap
    <
        string UIGroup = "Diffuse";
        string ResourceName = "";
        string ResourceType = "2D";
	    string UIWidget = "FilePicker";
	    string UIName = "";
        int mipmaplevels = 0;
    >;

    Texture2D _DetailMap
    <
        string UIGroup = "Diffuse";
        string ResourceName = "";
        string ResourceType = "2D";
	    string UIWidget = "FilePicker";
	    string UIName = "";
        int mipmaplevels = 0;
    >;
    
    // MISC //

    float _OutlineWidth
    <   
        string UIGroup = "Outline";
        string UIName = "";
    >;

    float3  _OutlineColor
    <   
        string UIGroup = "Outline";
        string UIWidget = "Color";
    >;

    bool _EnableUV2Check
    <
        string UIName = "";
        string UIGroup = "Diffuse";
    >;

    /////////////////////////////////////////////////////////////////////////////
    ////                               Struct                                ////
    /////////////////////////////////////////////////////////////////////////////

    // Vertex Shader Input //

    struct appdata_outline
    {
        float3 pos	: POSITION;
        float3 normalOS : NORMAL;
        float4 tangentOS : TANGENT;
        float2 UV0 : TEXCOORD0;
        float2 UV1 : TEXCOORD1;
        float2 UV2 : TEXCOORD2;
    };

    struct appdata
    {
        float3 pos	: POSITION;
        float3 normalOS : NORMAL;

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

    /////////////////////////////////////////////////////////////////////////////
    ////                           Vertex Shader                             ////
    /////////////////////////////////////////////////////////////////////////////

    vertexOutput_outline vertexShader_outline(appdata_outline IN)
    {
        vertexOutput_outline OUT = (vertexOutput_outline)0;

        float3 smoothNormalOS = Decode(IN.UV2);
        float3 posOS = IN.pos.xyz;

        posOS += smoothNormalOS * _OutlineWidth;
        float4 hpos = mul(float4(posOS, 1.0f), _Matrix_WVP);

        OUT.hpos = hpos;
        return OUT;
    }

    vertexOutput vertexShader(appdata IN)
    {   
        vertexOutput OUT = (vertexOutput)0;
        OUT.normalWS = mul(float4(IN.normalOS, 0.0f), _Matrix_W).xyz;
        OUT.hpos = mul(float4(IN.pos, 1.0f), _Matrix_WVP);
        #ifdef _MAYA_
            OUT.UV0 = FlipY(IN.UV0);
            OUT.UV1 = FlipY(IN.UV1);
        #else
            OUT.UV0 = IN.UV0;
            OUT.UV1 = IN.UV1;
        #endif
        OUT.UV2 = IN.UV2;
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
        // Pre //
        float3 n = IN.normalWS;
        float3 l = -_Light0Dir;
        float3 v = -_CameraPositionWS;

        float NoL_01 = dot(n,l) * 0.5 + 0.5;
        
        float4 ilmMap = _IlmMap.Sample(samplerState2D, IN.UV0);
        float4 detailMap = _DetailMap.Sample(samplerState2D, IN.UV1);
        float outline = ilmMap.a * detailMap.r;

        // Diffuse //
        float3 baseCol = _BaseColorMap.Sample(samplerState2D, IN.UV0).rgb;
        float3 sssCol = _SSSColorMap.Sample(samplerState2D, IN.UV0).rgb;
        float3 incidentLight = NoL_01 * _Light0Color * _Light0Intensity;
        incidentLight = step(0.5, incidentLight);
        float3 diffuse = lerp(sssCol, baseCol, incidentLight);

        // Specular //
        float3 specular = pow(saturate(dot(v, n)), 10);

        float3 finalColor;
        finalColor = (diffuse) * outline;

        if (_EnableUV2Check)
            finalColor = float3(IN.UV2, 1.0f);

        return float4(finalColor, 1.0f);
    }

    /////////////////////////////////////////////////////////////////////////////
    ////                             Technique                               ////
    /////////////////////////////////////////////////////////////////////////////

    // p0 //

    RasterizerState rasterizerState_p0
    {   
        #ifdef _MAYA_
            CullMode = Back;
        #else
            CullMode = Front;
        #endif
        FillMode = SOLID;
    };

    RasterizerState rasterizerState_p1
    {   
        #ifdef _MAYA_
            CullMode = Front;
        #else
            CullMode = Back;
        #endif
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


