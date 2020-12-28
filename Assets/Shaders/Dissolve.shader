Shader "Unlit/Dissolve"
{
    Properties
    {
        // パラメータ名 ("表示名", データ形式) = 初期値 という形で設定
        _Color ("Color", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float random(fixed2 uv, fixed2 size)
            {
                uv = frac(uv / size);
                return frac(sin(dot(uv, fixed2(12.9898, 78.233))) * 43758.5453);
            }

            fixed2 randVec(fixed2 uv, fixed2 size){
                return normalize(fixed2( random(uv, size), random(uv+fixed2(127.1, 311.7), size) ) * 2.0 + -1.0);
            }

            fixed2 bilinear(fixed f0, fixed f1, fixed f2, fixed f3, fixed fx, fixed fy)
            {
                return lerp( lerp(f0, f1, fx), lerp(f2, f3, fx), fy );
            }

            fixed fade(fixed t) { return t * t * t * (t * (t * 6.0 - 15.0) + 10.0); }

            fixed2 perlinNoise(fixed2 uv, fixed2 size)
            {
                fixed2 p = floor(uv * size);
                fixed2 f = frac(uv * size);

                fixed d00 = dot(randVec(p + fixed2(0, 0), size), f - fixed2(0, 0));
                fixed d01 = dot(randVec(p + fixed2(0, 1), size), f - fixed2(0, 1));
                fixed d10 = dot(randVec(p + fixed2(1, 0), size), f - fixed2(1, 0));
                fixed d11 = dot(randVec(p + fixed2(1, 1), size), f - fixed2(1, 1));

                return bilinear(d00, d10, d01, d11, fade(f.x), fade(f.y)) + 0.5f;
            }

            // プログラムから頂点シェーダーに渡される構造体
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            // 頂点シェーダーからフラグメントシェーダーに渡される構造体
            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = normalize(UnityObjectToWorldNormal(v.normal));
                o.uv = v.uv;
                return o;
            }

            fixed4 _Color;

            fixed4 frag (v2f i) : SV_Target
            {
                float alpha = perlinNoise(i.uv, fixed2(10, 10));
                float coefficient = 0.5;
                float threshold = frac(_Time.y * coefficient);
                clip(alpha - threshold);
                
                fixed4 color;
                float delta = 0.05f; // 微小値を0.05に設定
                if (alpha < threshold + delta)
                {
                    color = fixed4(1, 1, 1, 1);
                }
                else
                {
                    float intensity = 2.0f; // 明るさに関する補正値
                    color = _Color * max(0, dot(i.normal, normalize(_WorldSpaceLightPos0.xyz))) * intensity;
                }
                
                return color;
            }
            ENDCG
        }
    }
}
