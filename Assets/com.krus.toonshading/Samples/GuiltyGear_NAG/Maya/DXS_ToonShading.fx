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

    float3 gLamp0Dir : DIRECTION <
        string Object = "DirectionalLight0";
        string UIName =  "Lamp 0 Direction";
        string Space = (LIGHT_COORDS);
    > = {0.7f,-0.7f,-0.7f};

    float3 gLamp0Color : SPECULAR <
        string Object = "DirectionalLight0";
        string UIName =  "Lamp 0 Color";
        string UIWidget = "Color";
    > = {1.0f,1.0f,1.0f};

    float3 gAmbiColor : AMBIENT <
        string UIName =  "Ambient Light";
        string UIWidget = "Color";
    > = {0.07f,0.07f,0.07f};

    float3 gSurfaceColor : DIFFUSE <
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
        float3 Position	: POSITION;
        float3 Normal	: NORMAL;
    };

    struct vertexOutput
    {
        float4 HPosition	: POSITION;
        float3 LightVec		: TEXCOORD1;
        float3 WorldNormal	: TEXCOORD2;
        float3 WorldView	: TEXCOORD5;
    };

    /////////////////////////////////////////////////////////////////////////////
    ////                           Vertex Shader                             ////
    /////////////////////////////////////////////////////////////////////////////

    vertexOutput vertexShader(
        appdata IN,
        uniform float4x4 Matrix_W_IT,
        uniform float4x4 Matrix_W,
        uniform float4x4 Matrix_V_I,
        uniform float4x4 Matrix_WVP,
        uniform float3 LampDir)
    {
        vertexOutput OUT = (vertexOutput)0;
        OUT.WorldNormal = mul(float4(IN.Normal,0.0f),Matrix_W_IT).xyz;
        float4 Po = float4(IN.Position.xyz,1.0f); // homogeneous location coordinates
        float4 Pw = mul(Po,Matrix_W);	// convert to "world" space
        OUT.LightVec = -normalize(LampDir);
        OUT.WorldView = normalize(Matrix_V_I[3].xyz - Pw.xyz);
        OUT.HPosition = mul(Po,Matrix_WVP);
        return OUT;
    }

    void phong(
        vertexOutput IN,
        uniform float Kd,
        uniform float Ks,
        uniform float SpecExpon,
        float3 LightColor,
        uniform float3 AmbiColor,
        out float3 DiffuseContrib,
        out float3 SpecularContrib)
    {
        float3 Ln = normalize(IN.LightVec.xyz);
        float3 Nn = normalize(IN.WorldNormal);
        float3 Vn = normalize(IN.WorldView);
        float3 Hn = normalize(Vn + Ln);
        float4 litV = lit(dot(Ln,Nn),dot(Hn,Nn),SpecExpon);
        DiffuseContrib = litV.y * Kd * LightColor + AmbiColor;
        SpecularContrib = litV.z * Ks * LightColor;
    }

    /////////////////////////////////////////////////////////////////////////////
    ////                         Fragment Shader                             ////
    /////////////////////////////////////////////////////////////////////////////

    float4 fragmentShader(
        vertexOutput IN,
        uniform float3 SurfaceColor,
        uniform float Kd,
        uniform float Ks,
        uniform float SpecExpon,
        uniform float3 LampColor,
        uniform float3 AmbiColor) : COLOR
    {
        float3 diffContrib;
        float3 specContrib;
        phong(IN,Kd,Ks,SpecExpon,LampColor,AmbiColor,diffContrib,specContrib);
        float3 result = specContrib + (SurfaceColor * diffContrib);
        return float4(result,1.0f);
    }

    technique10 Simple10
    {
        pass p0
        {
            SetVertexShader(CompileShader(vs_4_0, vertexShader(Matrix_W_IT, Matrix_W, Matrix_V_I, Matrix_WVP, gLamp0Dir)));

            SetGeometryShader(NULL);

            SetPixelShader(CompileShader(ps_4_0,fragmentShader(gSurfaceColor, gKd, gKs, gSpecExpon, gLamp0Color, gAmbiColor)));
        }
    }


