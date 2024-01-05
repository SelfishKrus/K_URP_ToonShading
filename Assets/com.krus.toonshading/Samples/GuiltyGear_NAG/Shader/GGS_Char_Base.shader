//2021.07.10 简单实现. 马卡龙
Shader "Arc/GGS_Char_SimpleBase"
{
    Properties
    {
        _MainTex ("BaseTex", 2D) = "white" {}
        _ILMTex("ILMTex",2D) = "black"{}
        _SssTex("SssTex",2D) = "black"{}
        _DetailTex("DetailTex",2D) = "white"{}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode"="UniversalForward"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                half3 normal : NORMAL;
                half4 color : COLOR;
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                half4 vertexColor : TEXCOORD1;
                half3 worldNormal : TEXCOORD2;
                float3 worldPos : TEXCOORD3;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _ILMTex;
            sampler2D _SssTex;
            sampler2D _DetailTex;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv0, _MainTex);
                o.uv.zw = v.uv1;
                o.vertexColor = v.color;
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 ilm = tex2D(_ILMTex,i.uv.xy);
                fixed4 baseColor = tex2D(_MainTex, i.uv.xy);
                fixed3 sssColor = tex2D(_SssTex,i.uv.xy).rgb;
                fixed3 detail = tex2D(_DetailTex,i.uv.zw);
                half ao = saturate((i.vertexColor.r - 0.7) * 50);
                half3 worldNormal = normalize(i.worldNormal);
                half3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                half3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                half3 halfDir = normalize(worldLightDir + worldViewDir);
                half NdotH = saturate(dot(halfDir,worldNormal));
                half NdotL = dot(worldLightDir,worldNormal);
                half sssFactor = saturate((NdotL * 0.5 + 0.5 - i.vertexColor.b * 0.5) * 50) * ao;
                fixed4 finalColor = 1;
                finalColor.rgb = lerp(sssColor,baseColor,sssFactor) * detail * ilm.a;
                return finalColor;
            }
            ENDCG
        }
    }
}
