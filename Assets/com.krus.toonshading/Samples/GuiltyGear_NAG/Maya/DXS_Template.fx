    // Simple phong shader based on nVidia plastic example

    /******* Lighting Macros *******/
    /** To use "Object-Space" lighting definitions, change these two macros: **/
    #define LIGHT_COORDS "World"
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

    float3 gLamp0Dir : DIRECTION 
    <
        string Object = "DirectionalLight0";
        string UIName =  "Lamp 0 Direction";
        string Space = (LIGHT_COORDS);
    > = {0.7f,-0.7f,-0.7f};

    float3 gLamp0Color : SPECULAR 
    <
        string Object = "DirectionalLight0";
        string UIName =  "Lamp 0 Color";
        string UIWidget = "Color";
    > = {1.0f,1.0f,1.0f};

    float3 gAmbiColor : AMBIENT 
    <
        string UIName =  "Ambient Light";
        string UIWidget = "Color";
    > = {0.07f,0.07f,0.07f};

    float3 gSurfaceColor : DIFFUSE 
    <
        string UIName =  "Surface";
        string UIWidget = "Color";
    > = {0.0f,0.0f,1.0f};

    float gKd = 0.9f;
    float gKs = 0.4f;
    float gSpecExpon = 30.0f;

    /////////////////////////////////////////////////////////////////////////////
    ////                               Struct                                ////
    /////////////////////////////////////////////////////////////////////////////

    struct appdata
    {
        float3 pos	: POSITION;
        float3 normalOS	: NORMAL;
    };

    struct vertexOutput
    {
        float4 hpos	: POSITION;
        float3 normalWS : NORMAL;
    };

    /////////////////////////////////////////////////////////////////////////////
    ////                           Vertex Shader                             ////
    /////////////////////////////////////////////////////////////////////////////

    vertexOutput vertexShader(appdata IN)
    {   
        vertexOutput OUT = (vertexOutput)0; // to zero out all members
        OUT.normalWS = mul(float4(IN.normalOS, 0.0f), Matrix_W_IT).xyz;
        OUT.hpos = mul(float4(IN.pos, 1.0f), Matrix_WVP);
        return OUT;
    }

    /////////////////////////////////////////////////////////////////////////////
    ////                         Fragment Shader                             ////
    /////////////////////////////////////////////////////////////////////////////

    float4 fragmentShader(vertexOutput IN) : COLOR
    {
        float3 finalColor;
        finalColor = 1.0f;
        return float4(finalColor, 1.0f);
    }

    /////////////////////////////////////////////////////////////////////////////
    ////                             Technique                               ////
    /////////////////////////////////////////////////////////////////////////////

    RasterizerState rasterizerState
    {   
        // CullMode
        // NONE     - no culling
        // Front    - cull front
        // Back     - cull back
        CullMode = NONE;
        FillMode = SOLID;
    };

    DepthStencilState depthStencilState
    {
        DepthEnable = TRUE; 
    };

    

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


