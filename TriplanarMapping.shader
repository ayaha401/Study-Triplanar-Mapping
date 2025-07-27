Shader "Unlit/TriplanarMapping"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Scale("Texture Scale", Float) = 1.0
        _BlendSharpness("Blend Sharpness", Float) = 4.0
    }
    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100

        Pass
        {
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 posWS    : TEXCOORD0;
                float3 normalWS : NORMAL;
            };

            sampler2D _MainTex;
            
            CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float _Scale;
            float _BlendSharpness;
            CBUFFER_END

            Varyings vert(Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.posWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                return o;
            }

            float3 TriplanarBlend(float3 normal)
            {
                // 法線のXYZがそれぞれどの軸にどれぐらい向いていれば良いのかを知るためにabsする
                float3 blend = abs(normal);
                // powでブレンドを鋭くする
                blend = pow(blend, _BlendSharpness);
                // XYZの合計が1.0になるように正規化 どの軸にどれだけブレンドすればいいのかが明確になる
                return blend / (blend.x + blend.y + blend.z);
            }

            float4 SampleTriplanar(float3 worldPos, float3 worldNormal)
            {
                float3 blend = TriplanarBlend(worldNormal);
                float2 xUV = worldPos.yz * _Scale;
                float2 yUV = worldPos.zx * _Scale;
                float2 zUV = worldPos.xy * _Scale;

                float4 xProj = tex2D(_MainTex, xUV);
                float4 yProj = tex2D(_MainTex, yUV);
                float4 zProj = tex2D(_MainTex, zUV);

                return xProj * blend.x + yProj * blend.y + zProj * blend.z;
            }

            float4 frag(Varyings i) : SV_Target
            {
                return SampleTriplanar(i.posWS, i.normalWS);
            }
            ENDHLSL
        }
    }
}
