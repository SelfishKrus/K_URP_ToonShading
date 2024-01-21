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

    float4x4 Matrix_W : WORLD;
    float4x4 Matrix_W_I : WORLDINVERSE;
    float4x4 Matrix_W_IT : WORLDINVERSETRANSPOSE;

    float4x4 Matrix_V : VIEW;
    float4x4 Matrix_V_I : VIEWINVERSE;
    float4x4 Matrix_V_IT : VIEWINVERSETRANSPOSE;

    float4x4 Matrix_P : PROJECTION;
    float4x4 Matrix_P_I : PROJECTIONINVERSE;
    float4x4 Matrix_P_IT : PROJECTIONINVERSETRANSPOSE;

    float4x4 Matrix_WV : WORLDVIEW;
    float4x4 Matrix_WV_I : WORLDVIEWINVERSE;
    float4x4 Matrix_WV_IT : WORLDVIEWINVERSETRANSPOSE;

    float4x4 Matrix_WVP : WORLDVIEWPROJECTION;
    float4x4 Matrix_WVP_I : WORLDVIEWPROJECTIONINVERSE;
    float4x4 Matrix_WVP_IT : WORLDVIEWPROJECTIONINVERSETRANSPOSE;

    float4x4 Matrix_W_T : WORLDTRANSPOSE;
    float4x4 Matrix_V_T : VIEWTRANSPOSE;
    float4x4 Matrix_P_T : PROJECTIONTRANSPOSE;
    float4x4 Matrix_S : VIEWPORT;

    /////////////////////////////////////////////////////////////////////////////
    ////                              Properties                             ////
    /////////////////////////////////////////////////////////////////////////////

    // Light 0 //

    bool light0Enable : LIGHTENABLE
	<
		string Object = "Light 0";
		string UIName = "Enable Light 0";
		int UIOrder = 20;
    > = true;

    int light0Type : LIGHTTYPE
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
    


    /////////////////////////////////////////////////////////////////////////////
    ////                               Struct                                ////
    /////////////////////////////////////////////////////////////////////////////

    // Vertex Shader Input //

    struct appdata
    {
        float3 pos	: POSITION;
        float3 normalOS	: NORMAL;

        float2 UV0 : TEXCOORD0;
    };

    // Vertex Shader Output //

    struct vertexOutput
    {
        float4 hpos	: POSITION;
        float3 normalWS : NORMAL;

        float2 UV0 : TEXCOORD0;
    };

    /////////////////////////////////////////////////////////////////////////////
    ////                         Custom Functions                            ////
    /////////////////////////////////////////////////////////////////////////////

    float2 FlipY(float2 uv)
    {
        return float2(uv.x, 1.0f - uv.y);
    }

    /////////////////////////////////////////////////////////////////////////////
    ////                           Vertex Shader                             ////
    /////////////////////////////////////////////////////////////////////////////

    vertexOutput vertexShader(appdata IN)
    {   
        vertexOutput OUT = (vertexOutput)0; // to zero out all members
        OUT.normalWS = mul(float4(IN.normalOS, 0.0f), Matrix_W_IT).xyz;
        OUT.hpos = mul(float4(IN.pos, 1.0f), Matrix_WVP);
        
        OUT.UV0 = FlipY(IN.UV0);
        return OUT;
    }

    /////////////////////////////////////////////////////////////////////////////
    ////                         Fragment Shader                             ////
    /////////////////////////////////////////////////////////////////////////////

    float4 fragmentShader(vertexOutput IN) : COLOR
    {
        float3 finalColor;
        finalColor = _MainTex.Sample(samplerState, IN.UV0).rgb;
        return float4(finalColor, 1.0f);
    }

    /////////////////////////////////////////////////////////////////////////////
    ////                             Technique                               ////
    /////////////////////////////////////////////////////////////////////////////

    technique10 Simple10
    {
        pass p0
        {   
            SetVertexShader(CompileShader(vs_5_0, vertexShader()));
            SetHullShader(NULL);
            SetDomainShader(NULL);
            SetGeometryShader(NULL);
            SetPixelShader(CompileShader(ps_5_0,fragmentShader()));
        }
    }


